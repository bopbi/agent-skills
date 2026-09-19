# Publishing the rolling release

This runbook applies only to `bopbi/agent-skills`. It publishes the single
mutable rolling release and is not an installed user skill.

## Quick start

From a clean checkout on `main`, run:

```bash
./publish-release.sh
```

The script executes every preflight, publication, and post-publication check
below. It stops on the first failure and preserves its temporary workspace;
inspect the printed `release_dir` before retrying. The detailed commands below
are the source of truth for the release contract and recovery behavior.

## Release contract

- The only rolling release and tag are both named `latest`.
- Its asset is always named `agent-skills-main.tar.gz`.
- `install.sh` must use
  `https://github.com/bopbi/agent-skills/releases/latest/download/agent-skills-main.tar.gz`,
  never a tag-specific asset URL.
- Do not run `gh release delete`, delete the `latest` release, or delete the
  `latest` tag. Historical releases are outside this procedure.

## Preflight and artifact validation

Run these commands from a clean checkout on `main`. The intentional untracked
`plan/` directory is excluded from the clean-worktree check.

```bash
set -euo pipefail

repo_root="$(pwd)"
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
```

If a command fails, stop. Preserve `$release_dir` for inspection and report the
failing command; do not publish or delete anything.

## Publish

Push the validated commit before moving the rolling tag. The remote branch must
then equal the checked-out commit.

```bash
git push origin main
git fetch origin main
test "$release_sha" = "$(git rev-parse origin/main)"

git tag -f latest "$release_sha"
git push --force origin refs/tags/latest
test "$release_sha" = "$(git ls-remote origin refs/tags/latest | awk '{print $1}')"

gh release view latest --repo bopbi/agent-skills >/dev/null
gh release edit latest --repo bopbi/agent-skills --latest --title latest
gh release upload latest "$archive#agent-skills-main.tar.gz" --clobber --repo bopbi/agent-skills
```

`--clobber` deletes the old asset before uploading the replacement. If that
upload fails, stop and report the failure. Do not delete the release or tag as
a recovery attempt.

## Post-publication verification

```bash
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
```

Report success only after every post-publication command passes. On success,
remove the named workspace with:

```bash
rm -rf -- "$release_dir"
```
