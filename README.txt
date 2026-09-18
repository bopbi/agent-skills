# Claude Code skills

Personal [Claude Code](https://claude.com/claude-code) skills built around one idea:
**separate exploring, planning, and executing** so each step runs on the cheapest model that can do it.

```
/ask  ──►  /plan-task  ──►  /run-plan   (on the recommended model)
           /pr-triage  ──►  /run-plan  ──►  push  ──►  /pr-resolve
```

Plans are written as markdown into `plan/` in your repo. They are meant to be read in your editor,
left untracked (never committed), and never gitignored — so they stay visible and navigable in the IDE.

## Skills

| Command | What it does | Writes |
|---|---|---|
| `/ask <question>` | Read-only exploration and Q&A. Answers with `path:line` evidence. Never edits, never offers to. | nothing |
| `/plan-task <goal>` | Writes an implementation plan grounded in the real code, with a per-step **model tier recommendation** (small / standard / large / frontier) mapped to concrete Claude / OpenAI / Google models. Can reuse a prior `/ask` from the same session as its Context. | `plan/<date>-<slug>.md` |
| `/run-plan [file]` | Executes a plan from `plan/` step by step (newest draft by default). Hard-stops if any `→ Decision:` line in the plan is blank, and asks if you're on a lower model tier than it recommends. Runs the plan's Verification section, then writes `Status:` and an execution log back into the plan file. Never commits or touches GitHub. | `plan/<file>.md` (status + log) |
| `/pr-resolve` | The only skill that writes to GitHub. After `/run-plan` finished a `pr-<n>-review` plan and the fix is pushed, builds a reply for every thread from the plan's verdicts (fixed → "Fixed in `<sha>`" + resolve; not-valid / question / out-of-scope → drafted reply, left open for the reviewer), **previews the full list and asks for confirmation**, posts, and logs the result into the plan. `--dry-run` previews only. Depends on `pr-triage/` being installed alongside it. | `plan/<file>.md` (resolution log) + GitHub replies |
| `/pr-triage` | Run from a branch with an open PR. Fetches **all** review feedback in one call, judges each comment's validity against the code (valid / partial / not valid / question / out of scope), clusters by root cause regardless of order, and writes a resolution plan with a model recommendation. Never edits code, replies, or resolves threads. | `plan/<date>-pr-<n>-review.md` |

### Decisions are made while planning, never while executing

Plans separate three kinds of uncertainty:

- **Decisions** (what to build) — the planner asks you *before* writing the file. Only ones you explicitly defer land in the plan's **Needs your decision** section, each with a blank `→ Decision:` line.
- **Assumptions** — stated defaults with a fallback ("Assumed X; if wrong, step 4 becomes Y"). The executor follows them and logs it.
- **Execution-time unknowns** — written as conditional steps, never as questions.

`/run-plan` has a hard gate: it refuses to start while any `→ Decision:` line is blank, and won't accept "use your judgment". Answer in the file (you're reading it in your editor anyway) or in chat — it writes your answer into the file and proceeds. This keeps decisions with the model that had the full context, and keeps the cheap executor from guessing.

Each skill is restricted through `allowed-tools` in its frontmatter, so the "read-only" / "only writes to `plan/`" guarantees are enforced by Claude Code's permission system, not just by prompt wording.

## Install

```bash
git clone https://github.com/bopbi/agent-skills ~/.claude/skills
```

Or copy the individual skill folders into `~/.claude/skills/` (user-level) or `.claude/skills/` (project-level).

`/pr-triage` and `/pr-resolve` need the [GitHub CLI](https://cli.github.com/) (`gh auth login`) and `jq`.

## Model recommendation rubric

Plans recommend a **tier** — the cheapest one that can reliably execute each step — judged by **ambiguity and blast radius**, not by feature importance. The tier is provider-neutral; the plan then names a concrete model for whichever provider you use.

| Tier | Use for | Claude | OpenAI | Google | Kimi (Moonshot) | Qwen (Alibaba) | Grok (xAI) |
|---|---|---|---|---|---|---|---|
| small | mechanical, fully specified: renames, nits, boilerplate, mirrored tests | Haiku 4.5 | GPT-5.6 Luna | Gemini 3.5 Flash-Lite | Kimi K2.6 (cheapest current, not a small model) | qwen3.7-flash / qwen3-coder-flash | Grok Build 0.1 (beta) |
| standard | default: 2–5 files, clear requirement, established pattern | Sonnet 5 | GPT-5.6 Terra | Gemini 3.7 Flash | Kimi K2.7-Code | qwen3.7-plus / qwen3-coder-next | Grok 4.3 |
| large | cross-cutting or ambiguous: shared state, concurrency, unfamiliar code | Opus 5 | GPT-5.6 Sol | Gemini 3.1 Pro (preview) | Kimi K3 | Qwen3.8-Max | Grok 4.6 |
| frontier | genuinely hard *and* costly to get wrong | Fable 5 | GPT-5.5 Pro | Gemini 3.1 Pro (no higher tier yet) | Kimi K3 (`kimi-k3-swarm-max`, unverified) | Qwen3.8-Max (no higher tier) | Grok 4.6 (no Heavy API model) |

Model names are as of August 2026; edit the table in each `SKILL.md` as providers ship new ones. Switch models before running (Claude Code: `/model <name>`), then `/run-plan` — it will warn if you're on a lower tier than the plan recommends.

## License

MIT
