#!/bin/bash
# install-git.sh — install the agent-skills skills into the skills directory
# of every supported agent found in $HOME (~/.claude, ~/.agents, ~/.cursor,
# ~/.gemini, ~/.gemini/config, ~/.qwen, ~/.config/opencode).
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/bopbi/agent-skills/HEAD/install-git.sh | bash
#   ./install-git.sh
#
# Runtime dependencies: bash, plus git only in the piped mode.
set -euo pipefail

: "${REPO_URL:=https://github.com/bopbi/agent-skills.git}"

echo "Installing agent-skills skills..."

SOURCE_ROOT=""
SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd || true)"
if [ -n "$SELF_DIR" ] && [ -f "$SELF_DIR/ask/SKILL.md" ]; then
  if [ ! -f "$SELF_DIR/MODEL_TIERS.md" ]; then
    echo "error: model-tier policy not found beside local skills" >&2
    exit 1
  fi
  SOURCE_ROOT="$SELF_DIR"
else
  command -v git >/dev/null 2>&1 || { echo "error: git is required to fetch the skills repo" >&2; exit 1; }
  WORK_DIR="$(mktemp -d "${TMPDIR:-/tmp}/agent-skills-install.XXXXXX")"
  git clone --depth 1 "$REPO_URL" "$WORK_DIR/repo"
  if [ ! -f "$WORK_DIR/repo/ask/SKILL.md" ] || [ ! -f "$WORK_DIR/repo/MODEL_TIERS.md" ]; then
    echo "error: skills or model-tier policy not found after cloning (is $REPO_URL valid?)" >&2
    exit 1
  fi
  SOURCE_ROOT="$WORK_DIR/repo"
fi

skills=""
for skill_path in "$SOURCE_ROOT"/*/; do
  [ -f "$skill_path/SKILL.md" ] || continue
  skill_name="${skill_path%/}"
  skill_name="${skill_name##*/}"
  skills="$skills $skill_name"
done
if [ -z "$skills" ]; then
  echo "error: no skills (directories containing SKILL.md) found in $SOURCE_ROOT" >&2
  exit 1
fi

# name:home[:markers] — skills always go in <home>/skills/.
# Markers are comma-separated $HOME-relative directories that can identify an
# agent before its skills home exists.
# claude      → ~/.claude/skills                  Claude Code
# agents      → ~/.agents/skills                 shared convention
# cursor      → ~/.cursor/skills                 Cursor
# gemini      → ~/.gemini/skills                 Gemini CLI
# antigravity → ~/.gemini/config/skills          Google Antigravity
# qwen        → ~/.qwen/skills                   Qwen Code (best-known path)
# opencode    → ~/.config/opencode/skills        opencode
PROVIDERS="claude:.claude agents:.agents cursor:.cursor gemini:.gemini antigravity:.gemini/config:.gemini/antigravity,.gemini/antigravity-cli,.antigravity-ide qwen:.qwen opencode:.config/opencode"

installed=0
for entry in $PROVIDERS; do
  provider="${entry%%:*}"
  rest="${entry#*:}"
  case "$rest" in
    *:*)
      provider_home="${rest%%:*}"
      markers="${rest#*:}"
      ;;
    *)
      provider_home="$rest"
      markers=""
      ;;
  esac
  agent_home="$HOME/$provider_home"
  detected=0
  [ -d "$agent_home" ] && detected=1
  if [ "$detected" -eq 0 ] && [ -n "$markers" ]; then
    old_ifs="$IFS"
    IFS=","
    for marker in $markers; do
      [ -d "$HOME/$marker" ] && detected=1 && break
    done
    IFS="$old_ifs"
  fi
  [ "$detected" -eq 1 ] || continue
  skills_dir="$agent_home/skills"
  mkdir -p "$skills_dir"
  cp -p "$SOURCE_ROOT/MODEL_TIERS.md" "$skills_dir/MODEL_TIERS.md"
  echo "Model tier policy installed to $skills_dir/MODEL_TIERS.md"
  for skill_name in $skills; do
    cp -Rp "$SOURCE_ROOT/$skill_name" "$skills_dir/"
    echo "Skill '$skill_name' installed to $skills_dir/$skill_name"
    installed=$((installed + 1))
  done
done

if [ "$installed" -eq 0 ]; then
  echo "No supported agent directories found in $HOME" >&2
  if [ -n "${WORK_DIR:-}" ]; then
    echo "Temporary files left at: $WORK_DIR"
    echo "Clean up with: rm -rf \"$WORK_DIR\""
  fi
  exit 0
fi

if ! command -v gh >/dev/null 2>&1 || ! command -v jq >/dev/null 2>&1; then
  echo "Warning: pr-triage and pr-resolve need 'gh' (GitHub CLI, authenticated) and 'jq' on PATH." >&2
fi

if [ -n "${WORK_DIR:-}" ]; then
  echo "Temporary files left at: $WORK_DIR"
  echo "Clean up with: rm -rf \"$WORK_DIR\""
fi
