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
- **Overall tier:** <small | standard | large | frontier> — one sentence why.
- **Concrete model:** <model for the user's provider; see mapping>.
- **Per step (only where it differs):** e.g. "Step 3 → large: cross-module refactor with unclear ownership."
- **Switch with:** your tool's model switch (Claude Code: `/model <name>`).
```

### Choosing the model recommendation

The user wants to conserve spend. Recommend the **cheapest tier that can reliably execute each step**, judged by the step's *ambiguity and blast radius* — not by how important the feature is or how loud the reviewer was.

### Tier → model mapping

Recommend a **tier**, then name the concrete model for the provider the user is on (default: the provider you are running as). Names as of **August 2026** (checked against provider docs; entries marked *unverified* came from third-party coverage). Providers ship often — verify against the current model list before relying on an exact name.

| Tier | Use for | Claude | OpenAI | Google | Kimi (Moonshot) | Qwen (Alibaba) | Grok (xAI) |
|---|---|---|---|---|---|---|---|
| **small** | mechanical, fully specified by the plan: renames, nits, boilerplate, tests mirroring existing ones, single-site fixes | Haiku 4.5 | GPT-5.6 Luna | Gemini 3.5 Flash-Lite | Kimi K2.6 (cheapest current, not a small model) | qwen3.7-flash / qwen3-coder-flash | Grok Build 0.1 (beta) |
| **standard** | default: 2–5 files, clear requirement, established pattern, moderate debugging | Sonnet 5 | GPT-5.6 Terra | Gemini 3.7 Flash | Kimi K2.7-Code | qwen3.7-plus / qwen3-coder-next | Grok 4.3 |
| **large** | cross-cutting or ambiguous: shared state, concurrency, unfamiliar code, open questions, debugging with no clear cause | Opus 5 | GPT-5.6 Sol | Gemini 3.1 Pro (preview) | Kimi K3 | Qwen3.8-Max | Grok 4.6 |
| **frontier** | only if genuinely hard *and* costly to get wrong (migrations, security-sensitive logic, subtle correctness); justify why *large* isn't enough | Fable 5 | GPT-5.5 Pro | Gemini 3.1 Pro (no higher tier yet) | Kimi K3 (`kimi-k3-swarm-max`, unverified) | Qwen3.8-Max (no higher tier) | Grok 4.6 (no Heavy API model) |

Rules:
- Default to **standard** unless the work is mostly mechanical (→ small) or mostly ambiguous (→ large).
- When steps vary, give the per-step split so the user can run cheap parts on a cheap model and switch only for the hard ones.
- A well-written plan *lowers* the tier needed — if something needs *large* mainly because the plan is vague, tighten the plan instead.
- If the whole plan is small and mechanical, say so plainly: "small for everything."

## Ending your turn

Reply with: the file path written, a 2–4 sentence summary of the approach, and any open questions that need the user's decision. No "shall I implement this?".

$ARGUMENTS
