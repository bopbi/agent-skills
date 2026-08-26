---
name: plan-task
description: [personal] Write an implementation plan as a markdown file in the repo's plan/ directory (plan/<date>-<slug>.md) and stop — no code changes. Use after exploring with /ask, or when the user says "write a plan file", "plan this out into a file", "make a plan md", "draft the plan for". Distinct from the built-in interactive plan mode: this writes a file and stops. Reads the codebase to ground the plan in real files, but only ever writes inside plan/. Never touches .gitignore and never stages or commits the plan file.
metadata:
  author: Bobby Prabowo (bopbi)
  origin: personal
allowed-tools: Read, Grep, Glob, Write(plan/**), Edit(plan/**), Bash(mkdir -p plan:*), Bash(date:*), Bash(cat:*), Bash(head:*), Bash(tail:*), Bash(sed -n:*), Bash(ls:*), Bash(find:*), Bash(grep:*), Bash(rg:*), Bash(wc:*), Bash(tree:*), Bash(git status:*), Bash(git log:*), Bash(git diff:*), Bash(git show:*), Bash(git blame:*), Bash(git branch:*), Bash(git rev-parse:*), Agent(Explore)
---
# Plan task — write a plan markdown file, change nothing else

This is NOT the built-in plan mode. Do not call `EnterPlanMode`; the deliverable is a file.

Your only deliverable is a markdown file at `plan/<YYYY-MM-DD>-<slug>.md` in the repo root. The user reads it directly in their editor/IDE. You do **not** implement anything.

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

## Before writing

- Ground every step in real code: read the files you name, confirm symbols exist, cite `path:line`.
- Check `git status` / `git log --oneline -10` for in-flight work that the plan must account for.
- Check whether `plan/` already contains a plan for the same topic (`ls plan/`). If so, read it and either update it in place or write a new versioned file — say which you did.

## File naming

`plan/<YYYY-MM-DD>-<slug>.md`, where the date comes from `date +%F` and the slug is 2–5 lowercase hyphenated words describing the task (e.g. `plan/2026-08-26-api-rate-limiting.md`).

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

## Risks & open questions
Things that could go wrong, decisions still needed from the user, anything that couldn't be verified.

## Verification
How to confirm it works: tests to run/add, manual checks, commands.

## Model recommendation
- **Overall:** <haiku | sonnet | opus | fable> — one sentence why.
- **Per step (only where it differs from overall):** e.g. "Step 3 → opus: cross-module refactor with unclear ownership."
- **Switch with:** `/model <name>` before starting, and again before any step marked differently.
```

## Choosing the model recommendation

The user wants to conserve spend. Recommend the **cheapest model that can reliably execute each step**, not the best one. Judge by the step's *ambiguity and blast radius*, not by how important the feature is:

| Recommend | When the step is… |
|---|---|
| `haiku` (Haiku 4.5) | Mechanical and fully specified by the plan: renames, boilerplate, config edits, adding a test that mirrors an existing one, applying a pattern already present in the codebase, single-file changes with an obvious diff. |
| `sonnet` (Sonnet 5) | Typical feature work: 2–5 files, clear requirements, established patterns, moderate debugging. The default for most steps. |
| `opus` (Opus 5) | Cross-cutting or ambiguous: architectural changes, tricky concurrency/state, unfamiliar or undocumented code, steps where the plan itself lists open questions, debugging with no clear cause. |
| `fable` (Fable 5) | Only if the step is genuinely hard *and* the cost of getting it wrong is high (data migrations, security-sensitive logic, subtle correctness). Say explicitly why opus isn't enough. |

Rules:
- Default to `sonnet` overall unless the steps are mostly mechanical (→ `haiku`) or mostly ambiguous (→ `opus`).
- When steps vary, give the per-step split so the user can run the cheap steps on a cheap model and switch only for the hard ones. A well-written plan *lowers* the model needed — if a step needs `opus` mainly because the plan is vague, tighten the step instead.
- If the whole plan is small and mechanical, say so plainly: "`haiku` for everything."

Keep it tight — a plan the user can read in a couple of minutes. Prefer specific file paths and function names over generic advice. Flag any assumption you made in "Risks & open questions" rather than silently deciding.

## Ending your turn

Reply with: the file path written, a 2–4 sentence summary of the approach, and any open questions that need the user's decision. No "shall I implement this?".

$ARGUMENTS
