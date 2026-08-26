# Claude Code skills

Personal [Claude Code](https://claude.com/claude-code) skills built around one idea:
**separate exploring, planning, and executing** so each step runs on the cheapest model that can do it.

```
/ask  ──►  /plan-task  ──►  execute on the recommended model
           /pr-triage  ──►
```

Plans are written as markdown into `plan/` in your repo. They are meant to be read in your editor,
left untracked (never committed), and never gitignored — so they stay visible and navigable in the IDE.

## Skills

| Command | What it does | Writes |
|---|---|---|
| `/ask <question>` | Read-only exploration and Q&A. Answers with `path:line` evidence. Never edits, never offers to. | nothing |
| `/plan-task <goal>` | Writes an implementation plan grounded in the real code, with a per-step **model recommendation** (haiku / sonnet / opus / fable). Can reuse a prior `/ask` from the same session as its Context. | `plan/<date>-<slug>.md` |
| `/pr-triage` | Run from a branch with an open PR. Fetches **all** review feedback in one call, judges each comment's validity against the code (valid / partial / not valid / question / out of scope), clusters by root cause regardless of order, and writes a resolution plan with a model recommendation. Never edits code, replies, or resolves threads. | `plan/<date>-pr-<n>-review.md` |

Each skill is restricted through `allowed-tools` in its frontmatter, so the "read-only" / "only writes to `plan/`" guarantees are enforced by Claude Code's permission system, not just by prompt wording.

## Install

```bash
git clone https://github.com/bopbi/claude-skills ~/.claude/skills
```

Or copy the individual skill folders into `~/.claude/skills/` (user-level) or `.claude/skills/` (project-level).

`/pr-triage` needs the [GitHub CLI](https://cli.github.com/) (`gh auth login`) and `jq`.

## Model recommendation rubric

Plans recommend the cheapest model that can reliably execute each step, judged by **ambiguity and blast radius**, not by feature importance:

- `haiku` — mechanical and fully specified: renames, nits, boilerplate, tests mirroring existing ones
- `sonnet` — default: 2–5 files, clear requirement, established pattern
- `opus` — cross-cutting or ambiguous: shared state, concurrency, unfamiliar code, open questions
- `fable` — only when genuinely hard *and* costly to get wrong

Switch with `/model <name>` before the relevant step.

## License

MIT
