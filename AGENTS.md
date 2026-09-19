# Repository instructions for agents

## Publishing releases

Follow `RELEASING.md` for every release publication. It defines the required
rolling-release contract, validation, recovery behavior, and post-publication
checks; do not substitute ad-hoc GitHub release commands.

## Model-tier policy

`MODEL_TIERS.md` is the only hand-edited source for model tiers, provider/model
mappings, and compatibility rules. When a task changes any of that information:

1. Read and update `MODEL_TIERS.md` first.
2. Run `scripts/sync-model-tiers.sh` to update its managed consumers:
   `plan-task/SKILL.md`, `pr-triage/SKILL.md`, and `README.md`.
3. Run `scripts/sync-model-tiers.sh --check`; do not finish while it reports
   drift.
4. Review `run-plan/SKILL.md` if tier meanings, compatible-model-range output,
   provider-switch behavior, or legacy-plan handling changed.
5. Run the distribution checks for `install.sh`, `install-git.sh`, and
   `make-tarball.sh` when the canonical file location or installed content
   changes.

If a provider is added or removed, ensure the planner and triage templates
still direct agents to emit every provider listed in the canonical row.

Never hand-edit text between `BEGIN GENERATED MODEL-TIER POLICY` and
`END GENERATED MODEL-TIER POLICY` in a consumer. Edit the canonical source and
regenerate it instead.

## Skill portability

Skills in this repo install into multiple coding agents (Claude Code, Kimi
Code, Cursor, Gemini CLI, Qwen Code, opencode), so SKILL.md bodies must stay
agent-neutral:

- Refer to the skill's own directory as `<skill-dir>` (the directory
  containing the SKILL.md, resolved from the path the agent loaded it from).
  Never use `${CLAUDE_SKILL_DIR}` or any other agent-specific variable.
- `allowed-tools` frontmatter is enforced only on agents that support it
  (Claude Code); elsewhere the restrictions are prompt-level. Keep each
  skill's "Hard rules" section self-sufficient — it must hold even when
  nothing enforces it.
