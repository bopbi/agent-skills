---
name: plan-task
description: Write an implementation plan as a markdown file in the repo's plan/ directory (plan/<date>-<slug>.md) and stop — no code changes. Large or complex tasks may be split into an index file plus ordered part files (plan/<date>-<slug>.md + plan/<date>-<slug>-NN-<part>.md), proposed as a breakdown and confirmed with the user before writing. Use after exploring with /ask, or when the user says "write a plan file", "plan this out into a file", "make a plan md", "draft the plan for". Distinct from the built-in interactive plan mode — this writes a file and stops. Reads the codebase to ground the plan in real files, but only ever writes inside plan/. Never touches .gitignore and never stages or commits the plan file.
metadata:
  author: Bobby Prabowo (bopbi)
  origin: personal
allowed-tools: Read, Grep, Glob, Write(plan/**), Edit(plan/**), Bash(mkdir -p plan:*), Bash(date:*), Bash(cat:*), Bash(head:*), Bash(tail:*), Bash(sed -n:*), Bash(ls:*), Bash(find:*), Bash(grep:*), Bash(rg:*), Bash(wc:*), Bash(tree:*), Bash(git status:*), Bash(git log:*), Bash(git diff:*), Bash(git show:*), Bash(git blame:*), Bash(git branch:*), Bash(git rev-parse:*), Agent(Explore)
---
# Plan task — write a plan markdown file, change nothing else

This is NOT the built-in plan mode. Do not call `EnterPlanMode`; the deliverable is a file.

Your only deliverable is one or more markdown files inside the repo root's `plan/` directory: a single plan at `plan/<YYYY-MM-DD>-<slug>.md`, or — for large/complex tasks (see "Splitting large tasks" below) — an index file plus ordered part files. The user reads them directly in their editor/IDE. You do **not** implement anything.

## Hard rules

1. **Write only inside `plan/`.** Create the directory if missing (`mkdir -p plan`). Do not create, edit, move, or delete any other file.
2. **Do not touch `.gitignore`, `.git/info/exclude`, or any git config.** The user deliberately keeps `plan/` untracked-but-visible so it stays navigable in the IDE. Do not "helpfully" ignore it.
3. **Never `git add`, `git commit`, or stage anything.** The plan file must remain an untracked local file. If `git status` shows `plan/` is already staged or tracked, say so in your reply as an observation — do not fix it.
4. **Do not enter plan mode** (`EnterPlanMode`/`ExitPlanMode`) — the plan file *is* the plan.
5. **Do not start implementing** after writing the file, and do not offer to. End your turn with the file path and a one-paragraph summary.

## Input

`$ARGUMENTS` is the task to plan. It may be:
- A free-text goal ("add rate limiting to the API"), or
- A reference to earlier exploration in this conversation ("based on the /ask above", "plan the fix for the issue you found"). In that case, **reuse the findings, file references, and open questions from that `/ask` answer** as the plan's Context section — don't re-derive them from scratch, but do re-read files you need to verify specifics.

If the task is too vague to plan (no identifiable goal), ask one clarifying question instead of writing a file.

## Splitting large tasks

Small and medium tasks keep producing a single plan file, exactly as today. Consider splitting only when the task is genuinely large or complex:

- The steps span multiple subsystems or components, or
- There are more than roughly 8–10 steps, or
- The work has natural phases that are independently reviewable or releasable.

When you judge a split is warranted, **propose before you write**:

1. Draft a default breakdown — by phase or component — where each part is independently executable and reviewable on its own.
2. Show the user the proposed parts, each with a one-line scope.
3. Ask the user to confirm or adjust the breakdown.
4. Only after confirmation, write the files (index + parts; see "File naming" and "Plan file template").

Do not split without proposing first, and do not write files before the user confirms — a wrong split means rewriting plan files.

## Decisions vs. assumptions — resolve decisions *now*, not at execution

The plan will be executed later, often by a cheaper model with less context. It must be fully specified. While planning, sort every uncertainty into one of three buckets:

- **Decision** — changes *what* gets built (approach A vs B, keep or drop a behaviour, scope trade-off). **Ask the user before writing the file** (one question per decision, options with trade-offs). Only if the user explicitly defers ("decide later") does it go into the plan's "Needs your decision" section — and then the plan states which steps are blocked on it.
- **Assumption** — you couldn't verify it but there is a sensible default. Do not ask. Write it as a stated default with its fallback: "Assumed X (`path:line` suggests so); if wrong, step 4 becomes Y." The executor follows the default and logs it.
- **Execution-time unknown** — only answerable while doing the work ("does a test for this exist?"). Never a question: write a conditional step ("If `tests/foo_test.ts` exists, extend it; otherwise create it from `tests/bar_test.ts`").

A plan with zero items under "Needs your decision" is the goal. Every item left there blocks `/run-plan` until the user writes a `→ Decision:` line under it.

## Before writing

- Ground every step in real code: read the files you name, confirm symbols exist, cite `path:line`.
- Check `git status` / `git log --oneline -10` for in-flight work that the plan must account for.
- Check whether `plan/` already contains a plan for the same topic (`ls plan/`). If so, read it and either update it in place or write a new versioned file — say which you did.

## File naming

Single-file plans: `plan/<YYYY-MM-DD>-<slug>.md`, where the date comes from `date +%F` and the slug is 2–5 lowercase hyphenated words describing the task (e.g. `plan/2026-08-26-api-rate-limiting.md`).

Multi-file plans:
- Index: `plan/<YYYY-MM-DD>-<slug>.md` — shared Goal/Context/Approach/Decisions plus the ordered part list.
- Parts: `plan/<YYYY-MM-DD>-<slug>-NN-<part>.md`, where `NN` is a zero-padded execution order (`01`, `02`, …) and `<part>` is a short slug naming the part (e.g. `plan/2026-08-26-api-rate-limiting-02-middleware.md`).

## Plan file template

```markdown
# <Title>

- **Status:** draft
- **Created:** <YYYY-MM-DD>
- **Source:** <"/ask: <question>" or "user request">

## Goal
One or two sentences: what will be true when this is done.

## Context
What was learned during exploration. File references (`path:line`), how the relevant code works today, constraints discovered. Pull this from the prior /ask if there was one.

## Non-goals
What this plan deliberately does not cover.

## Approach
The chosen approach and *why*, plus alternatives considered and rejected (briefly).

## Steps
Ordered, concrete, each step small enough to verify on its own.
1. `path/to/file.ext` — what changes and why.
2. …

## Assumptions
Stated defaults with fallbacks: "Assumed X; if wrong, step N becomes Y." (Not questions.)

## Needs your decision
Only decisions the user explicitly deferred while planning. Each item names the steps it blocks and leaves a line for the answer:
- **D1.** <question> — options: A (…) / B (…). Blocks steps 3–4.
  → Decision:

## Risks
Things that could go wrong during execution and what to watch for.

## Verification
How to confirm it works: tests to run/add, manual checks, commands.

## Model recommendation
- **Overall tier:** <small | standard | large | frontier> — one sentence why.
- **Compatible model range:** List every provider/model entry from the canonical policy row matching the overall tier.
- **Per step (only where it differs):** e.g. "Step 3 → large — compatible model range: list every provider/model entry from the matching row."
- **Execution compatibility:** Any listed model, or a verified higher-tier model, is acceptable even when it differs from the model used to create the plan. Record the actual provider, model, and tier in the execution log.
```

### Multi-file plan templates

Use these when the task was split (see "Splitting large tasks"). Shared context lives in the index; each part points back to it instead of duplicating it.

Index template:

```markdown
# <Title>

- **Status:** draft
- **Created:** <YYYY-MM-DD>
- **Source:** <"/ask: <question>" or "user request">

## Goal
One or two sentences covering the whole task.

## Context
What was learned during exploration, shared by all parts. File references (`path:line`), constraints.

## Approach
The chosen approach for the whole task and *why*, plus alternatives considered and rejected (briefly).

## Parts
Ordered list; each part is independently executable and reviewable.
1. [Part 01 — <title>](<YYYY-MM-DD>-<slug>-01-<part>.md) — <one-line scope>. Depends on: none.
2. [Part 02 — <title>](<YYYY-MM-DD>-<slug>-02-<part>.md) — <one-line scope>. Depends on: part 01.
3. …

## Assumptions
Stated defaults with fallbacks, shared across parts.

## Needs your decision
Only decisions the user explicitly deferred while planning. Each item names the parts it blocks and leaves a line for the answer:
- **D1.** <question> — options: A (…) / B (…). Blocks parts 2–3.
  → Decision:

## Risks
Things that could go wrong during execution and what to watch for.

## Model recommendation
- **Overall tier:** <small | standard | large | frontier> — one sentence why, for the whole task.
- **Compatible model range:** List every provider/model entry from the canonical policy row matching the overall tier.
- **Per part (only where it differs):** e.g. "Part 2 → large — compatible model range: list every provider/model entry from the matching row."
- **Execution compatibility:** Any listed model, or a verified higher-tier model, is acceptable even when it differs from the model used to create the plan. Record the actual provider, model, and tier in the execution log.
```

Part template:

```markdown
# <Title> — Part NN: <part name>

- **Status:** draft
- **Created:** <YYYY-MM-DD>
- **Source:** <same as index>
- **Index:** [<index slug>](../<YYYY-MM-DD>-<slug>.md)

## Goal
One or two sentences: what will be true when this part is done.

## Context
Only what this part needs beyond the index — read the index first (`<YYYY-MM-DD>-<slug>.md`).

## Steps
Ordered, concrete, each step small enough to verify on its own.
1. `path/to/file.ext` — what changes and why.
2. …

## Assumptions
Stated defaults with fallbacks specific to this part. (Not questions.)

## Needs your decision
Only decisions the user explicitly deferred while planning this part, plus any index-level items this part says it blocks on. Each item names the steps it blocks and leaves a line for the answer:
- **D1.** <question> — options: A (…) / B (…). Blocks steps 3–4.
  → Decision:

## Risks
Things that could go wrong during this part's execution and what to watch for.

## Verification
How to confirm this part works: tests to run/add, manual checks, commands.

## Model recommendation
- **Overall tier:** <small | standard | large | frontier> — one sentence why, for this part.
- **Compatible model range:** List every provider/model entry from the canonical policy row matching this part's tier.
- **Execution compatibility:** Any listed model, or a verified higher-tier model, is acceptable even when it differs from the model used to create the plan. Record the actual provider, model, and tier in the execution log.
```

### Choosing the model recommendation

The user wants to conserve spend. Recommend the **cheapest tier that can reliably execute each step**, judged by the step's *ambiguity and blast radius* — not by how important the feature is or how loud the reviewer was.

### Tier → model mapping

Before recommending a model, read the canonical policy at `../model-tier-data/MODEL_TIERS.md`.
Choose the tier first, then emit every provider/model entry from its matching row
as the compatible model range. Do not privilege the provider or model used to
create the plan.

<!-- BEGIN GENERATED MODEL-TIER POLICY -->
**Policy source:** This block is generated from `MODEL_TIERS.md`; do not edit
it in this consumer.

Plans recommend the cheapest **tier** that can reliably execute each step or
cluster, judged by ambiguity and blast radius rather than feature importance.
Every recommendation also emits a **compatible model range**: one model from
each supported provider at that tier. The tier is the requirement, not the
provider that created the plan, so execution may switch providers when the
selected model is listed for, or verified above, the required tier.

| Tier | Use for | Claude | OpenAI | Google | Kimi (Moonshot) | Qwen (Alibaba) | Grok (xAI) |
|---|---|---|---|---|---|---|---|
| small | mechanical, fully specified: renames, nits, boilerplate, mirrored tests | `claude-haiku-4-5` | `gpt-5.6-luna` | `gemini-3.5-flash-lite` | `kimi-k2.7-code-highspeed` (lowest-cost current option, not a small-capability model) | `qwen3.8-flash` | `grok-build-0.1` |
| standard | default: 2–5 files, clear requirement, established pattern | `claude-sonnet-5` | `gpt-5.6-terra` | `gemini-3.7-flash` | `kimi-k2.8-preview` | `qwen3.7-plus` | `grok-4.3` |
| large | cross-cutting or ambiguous: shared state, concurrency, unfamiliar code | `claude-opus-5-5` | `gpt-5.6-sol` | `gemini-3.8-flash` | `kimi-k3` (long-context variant: `kimi-k3-256k`) | `qwen3.8-max` | `grok-4.6` |
| frontier | genuinely hard and costly to get wrong | `claude-fable-5-1` | `gpt-5.5-pro` | `gemini-3.8-flash` (no higher general-purpose production API model) | `kimi-k3` with `reasoning_effort: "max"` (no separate frontier model; long-context variant: `kimi-k3-256k`) | `qwen3.8-max` (no higher general-purpose production API model) | `grok-4.6` (no higher general-purpose production API model) |

Model IDs are current as of **September 2026**. Providers ship often, so
verify current availability before relying on an exact ID. Default to
**standard** unless work is fully mechanical (small) or cross-cutting or
ambiguous (large); use frontier only when large is insufficient and mistakes
would be unusually costly.
<!-- END GENERATED MODEL-TIER POLICY -->

Rules:
- When steps vary, give the per-step split so the user can run cheap parts on a cheap model and switch only for the hard ones.
- A user may switch providers between planning and execution if the execution model is listed for, or is verified above, the required tier.
- A well-written plan *lowers* the tier needed — if something needs *large* mainly because the plan is vague, tighten the plan instead.
- If the whole plan is small and mechanical, say so plainly: "small for everything."

## Ending your turn

Reply with: the file path written (when multiple files were written, list every path with the index first), a 2–4 sentence summary of the approach, and — if any — the deferred decisions (D1, D2…) that must be answered in the file before `/run-plan` will start. No "shall I implement this?".

$ARGUMENTS
