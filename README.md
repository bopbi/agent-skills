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
| `/plan-task <goal>` | Writes an implementation plan grounded in the real code, with a per-step **model tier recommendation** (small / standard / large / frontier) and a compatible provider/model range. Can reuse a prior `/ask` from the same session as its Context. | `plan/<date>-<slug>.md` |
| `/run-plan [file]` | Executes a plan from `plan/` step by step (newest draft by default). Hard-stops if any `→ Decision:` line in the plan is blank, and asks if its model tier is lower than the plan requires; a matching-tier model from another provider is accepted. Runs the plan's Verification section, then writes `Status:` and an execution log back into the plan file. Never commits or touches GitHub. | `plan/<file>.md` (status + log) |
| `/pr-resolve` | The only skill that writes to GitHub. After `/run-plan` finished a `pr-<n>-review` plan and the fix is pushed, builds a reply for every thread from the plan's verdicts (fixed → "Fixed in `<sha>`" + resolve; not-valid / question / out-of-scope → drafted reply, left open for the reviewer), **previews the full list and asks for confirmation**, posts, and logs the result into the plan. `--dry-run` previews only. Depends on `pr-triage/` being installed alongside it. | `plan/<file>.md` (resolution log) + GitHub replies |
| `/pr-triage` | Run from a branch with an open PR. Fetches **all** review feedback in one call, judges each comment's validity against the code (valid / partial / not valid / question / out of scope), clusters by root cause regardless of order, and writes a resolution plan with a tier and compatible provider/model range. Never edits code, replies, or resolves threads. | `plan/<date>-pr-<n>-review.md` |

### Decisions are made while planning, never while executing

Plans separate three kinds of uncertainty:

- **Decisions** (what to build) — the planner asks you *before* writing the file. Only ones you explicitly defer land in the plan's **Needs your decision** section, each with a blank `→ Decision:` line.
- **Assumptions** — stated defaults with a fallback ("Assumed X; if wrong, step 4 becomes Y"). The executor follows them and logs it.
- **Execution-time unknowns** — written as conditional steps, never as questions.

`/run-plan` has a hard gate: it refuses to start while any `→ Decision:` line is blank, and won't accept "use your judgment". Answer in the file (you're reading it in your editor anyway) or in chat — it writes your answer into the file and proceeds. This keeps decisions with the model that had the full context, and keeps the cheap executor from guessing.

Each skill is restricted through `allowed-tools` in its frontmatter, so the "read-only" / "only writes to `plan/`" guarantees are enforced by Claude Code's permission system, not just by prompt wording.

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/bopbi/agent-skills/HEAD/install.sh | bash
```

Or clone the repo and run `./install.sh`. For a git-based one-liner, use:

```bash
curl -fsSL https://raw.githubusercontent.com/bopbi/agent-skills/HEAD/install-git.sh | bash
```

Either way, the script copies the skills into every agent it finds (`~/.claude/skills/`, `~/.agents/skills/`, `~/.cursor/skills/`, `~/.gemini/skills/`, `~/.gemini/config/skills/`, `~/.qwen/skills/`, `~/.config/opencode/skills/`): skills already there are left alone, same-named ones are merged over, and re-running updates the copies. The `install-git.sh` variant requires git.

`/pr-triage` and `/pr-resolve` need the [GitHub CLI](https://cli.github.com/) (`gh auth login`) and `jq`.

## Model recommendation rubric

Plans recommend a **tier** — the cheapest one that can reliably execute each step — judged by **ambiguity and blast radius**, not by feature importance. Each plan also emits a **compatible model range**: one model from every supported provider for that tier. The tier is the requirement, not the provider that made the plan, so execution may switch providers when the selected model is listed for or verified above the required tier.

| Tier | Use for | Claude | OpenAI | Google | Kimi (Moonshot) | Qwen (Alibaba) | Grok (xAI) |
|---|---|---|---|---|---|---|---|
| small | mechanical, fully specified: renames, nits, boilerplate, mirrored tests | `claude-haiku-4-5` | `gpt-5.6-luna` | `gemini-3.5-flash-lite` | `kimi-k2.6` (lowest-cost current option, not a small-capability model) | `qwen3.8-flash` | `grok-build-0.1` |
| standard | default: 2–5 files, clear requirement, established pattern | `claude-sonnet-5` | `gpt-5.6-terra` | `gemini-3.7-flash` | `kimi-k2.7-code` | `qwen3.7-plus` | `grok-4.3` |
| large | cross-cutting or ambiguous: shared state, concurrency, unfamiliar code | `claude-opus-5` | `gpt-5.6-sol` | `gemini-3.8-flash` | `kimi-k3` | `qwen3.8-max` | `grok-4.6` |
| frontier | genuinely hard *and* costly to get wrong | `claude-fable-5-1` | `gpt-5.5-pro` | `gemini-3.8-flash` (no higher general-purpose production API model) | `kimi-k3` with `reasoning_effort: "max"` (no separate frontier model) | `qwen3.8-max` (no higher general-purpose production API model) | `grok-4.6` (no higher general-purpose production API model) |

Model IDs are current as of September 2026; update the table in each `SKILL.md` together as providers ship new ones. Before execution, select any compatible provider/model from the plan's range using that tool's model selector, then run `/run-plan`; it will warn before running below the required tier.

## License

MIT
