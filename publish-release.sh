#!/bin/bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$repo_root"
release_dir=""
trap 'status=$?; printf "Release failed (exit %s): %s\n" "$status" "$BASH_COMMAND" >&2; exit "$status"' ERR

test "$(git branch --show-current)" = main
git fetch --prune origin
test "$(git rev-list --count HEAD..origin/main)" = 0
test -z "$(git status --short -- . ':(exclude)plan/**')"
gh auth status
test "$(gh repo view bopbi/agent-skills --json nameWithOwner --jq .nameWithOwner)" = bopbi/agent-skills
bash -n install.sh install-git.sh
grep -Fqx ': "${TARBALL_URL:=https://github.com/bopbi/agent-skills/releases/latest/download/agent-skills-main.tar.gz}"' install.sh
scripts/sync-model-tiers.sh --check

release_dir="$(mktemp -d "${TMPDIR:-/tmp}/agent-skills-release.XXXXXX")"
archive="$release_dir/agent-skills-main.tar.gz"
printf 'Release workspace: %s\n' "$release_dir"
./make-tarball.sh "$archive"
tar -tzf "$archive" | grep -Fx 'agent-skills-main/MODEL_TIERS.md'
for skill in */SKILL.md; do
  tar -tzf "$archive" | grep -Fx "agent-skills-main/$skill"
done
! tar -tzf "$archive" | grep -Fqx 'agent-skills-main/RELEASING.md'

mkdir -p "$release_dir/home/.agents" "$release_dir/run"
(
  cd "$release_dir/run"
  HOME="$release_dir/home" TARBALL_URL="file://$archive" bash < "$repo_root/install.sh"
)
test -f "$release_dir/home/.agents/skills/ask/SKILL.md"
test -f "$release_dir/home/.agents/skills/model-tier-data/MODEL_TIERS.md"
test ! -e "$release_dir/home/.agents/skills/MODEL_TIERS.md"
test ! -e "$release_dir/home/.agents/skills/publish-release"
release_sha="$(git rev-parse HEAD)"
archive_sha="$(shasum -a 256 "$archive" | awk '{print $1}')"

git push origin main
git fetch origin main
test "$release_sha" = "$(git rev-parse origin/main)"

git tag -f latest "$release_sha"
git push --force origin refs/tags/latest
test "$release_sha" = "$(git ls-remote origin refs/tags/latest | awk '{print $1}')"

gh release view latest --repo bopbi/agent-skills >/dev/null
gh release edit latest --repo bopbi/agent-skills --latest --title latest
gh release upload latest "$archive#agent-skills-main.tar.gz" --clobber --repo bopbi/agent-skills

gh release view latest --repo bopbi/agent-skills \
  --json tagName,isDraft,isPrerelease,assets \
  --jq '.tagName, .isDraft, .isPrerelease, (.assets[] | "\(.name) \(.digest)")'
test "$release_sha" = "$(git ls-remote origin refs/tags/latest | awk '{print $1}')"

curl -fsSL \
  https://github.com/bopbi/agent-skills/releases/latest/download/agent-skills-main.tar.gz \
  -o "$release_dir/downloaded.tar.gz"
test "$archive_sha" = "$(shasum -a 256 "$release_dir/downloaded.tar.gz" | awk '{print $1}')"

mkdir -p "$release_dir/remote-home/.agents" "$release_dir/remote-run"
curl -fsSL https://raw.githubusercontent.com/bopbi/agent-skills/HEAD/install.sh |
  (
    cd "$release_dir/remote-run"
    HOME="$release_dir/remote-home" bash
  )
test -f "$release_dir/remote-home/.agents/skills/ask/SKILL.md"
test -f "$release_dir/remote-home/.agents/skills/model-tier-data/MODEL_TIERS.md"
test ! -e "$release_dir/remote-home/.agents/skills/MODEL_TIERS.md"

printf 'Published %s (%s)\\n' "$release_sha" "$archive_sha"
rm -rf -- "$release_dir"
