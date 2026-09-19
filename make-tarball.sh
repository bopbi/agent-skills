#!/bin/bash
# make-tarball.sh — create a GitHub-layout tarball for offline installer tests.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd)"
OUTPUT="${1:-$REPO_ROOT/agent-skills-main.tar.gz}"
skills=""
for skill_path in "$REPO_ROOT"/*/; do
  [ -f "$skill_path/SKILL.md" ] || continue
  skill_name="${skill_path%/}"
  skill_name="${skill_name##*/}"
  skills="$skills $skill_name"
done
[ -n "$skills" ] || { echo "error: no skills found in $REPO_ROOT" >&2; exit 1; }
[ -f "$REPO_ROOT/MODEL_TIERS.md" ] || { echo "error: model-tier policy not found in $REPO_ROOT" >&2; exit 1; }

tar -czf "$OUTPUT" -C "$REPO_ROOT" -s ',^,agent-skills-main/,' $skills README.md LICENSE AGENTS.md MODEL_TIERS.md
echo "Created: $OUTPUT"
echo "Offline test: TARBALL_URL=file://$OUTPUT bash ./install.sh"
