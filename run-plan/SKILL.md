---
name: run-plan
description: Execute a plan file from the repo's plan/ directory (written by /plan-task or /pr-triage) step by step, run its Verification section, and record the outcome back into the plan. Use when the user says "run the plan", "execute the plan", "implement plan/<file>", or "do the plan" — optionally naming a file; defaults to the newest draft in plan/. Checks the plan's model-tier recommendation against the current model before starting. Does not commit, push, or touch GitHub unless asked.
metadata:
  author: Bobby Prabowo (bopbi)
  origin: personal
allowed-tools: Read, Grep, Glob, Edit, Write, Bash, Agent(Explore)
---
# Run plan — execute a plan file, then close the loop

The plan was written deliberately (via `/plan-task` or `/pr-triage`) so that execution can run on a cheaper model with less context. Your job is to **follow it**, not to re-plan it.

## Step 0 — Locate and load the plan

- `$ARGUMENTS` may name a file (`plan/2026-08-26-foo.md` or just `foo`) — match it under `plan/`. Otherwise pick the newest `plan/*.md` whose `Status:` is `draft` or `in-progress`. If none, say so and stop.
- Read the whole plan. Also run `git status --short` — if the working tree has unrelated uncommitted changes, say so and ask whether to continue (they could be mixed into this work).
- If `Status: done`, stop and say so unless the user explicitly wants a re-run.

## Step 1 — Preflight (answer these in your reply before editing anything)

1. **Decisions resolved? (hard gate)** Every item under "Needs your decision" must have a filled-in `→ Decision:` line in the plan file. If any is blank, list the open items (D1, D2…) with their options and **stop**. Do not decide yourself, and do not accept "use your judgment" as an answer — the plan was written by a model with more context than you have now. Two ways the user can answer: edit the plan file directly, or tell you the answer in chat, in which case you write it into the `→ Decision:` line (that edit is allowed) and then continue. "Either — pick the simpler one" is a valid recorded decision; a blank line is not.
   "Assumptions" are different: follow each stated default without asking, and if you find one is wrong, apply its stated fallback and note it in the log.
2. **Model tier.** Identify the provider, model, and tier you are running as, then compare that tier with the plan's `Overall tier` and any per-step/per-cluster exception. The plan's `Compatible model range` is provider-neutral: a listed model from another provider, or a verified higher-tier model, is acceptable. If you are a *higher* tier than recommended, note it in one line (spending more than needed) and continue. If you are a *lower* tier, or cannot determine your model's tier, state that plainly; show the required tier's compatible model range (or the legacy `Concrete model` when an older plan has no range), then ask whether to continue anyway or switch with the current tool's provider-specific model selector. Do not silently proceed on a step the plan flagged as needing more.
3. **Scope.** State the steps you will execute and the files they touch, from the plan. Nothing else.

Then set the plan's `Status:` to `in-progress`.

## Step 2 — Execute, in the plan's order

- Do each step as written. Read the files it names; keep them loaded across steps that share them.
- If a step's premise is wrong (the code has changed, the symbol doesn't exist, the step would break something the plan didn't foresee), **do not improvise a redesign**. Do the smallest correct thing, and record the deviation in the log. If the deviation is material (changes the approach, touches files outside the plan's scope), stop and ask.
- Stay inside the plan's scope and non-goals. No opportunistic refactors, no "while I'm here".
- For `/pr-triage` plans: implement ✅ and ⚠️ clusters only. Do **not** reply to, resolve, or otherwise touch GitHub threads — that is a separate, explicit step for the user.

## Step 3 — Verify

Run everything in the plan's "Verification" section (tests, lint, typecheck, manual checks). Report results honestly, including failures — do not mark a step done if its verification failed. If a test fails because of the plan's own design rather than your implementation, say so and stop rather than patching around it.

## Step 4 — Close the loop in the plan file

Edit the plan file (only inside `plan/`):
- `Status:` → `done` if every step passed verification, otherwise `blocked` with a one-line reason.
- Append an `## Execution log` section:

```markdown
## Execution log
- **Planned tier / compatible model range:** <tier> / <range from the plan>
- **Executed:** <YYYY-MM-DD> on <provider> / <model> (<tier>)
- **Provider switch:** none, or <planning provider/model if known> → <execution provider/model>
- **Steps:** 1 ✅, 2 ✅, 3 ⚠️ deviated (<why>), 4 ⏭ skipped (<why>)
- **Verification:** <commands run and results>
- **Deviations / decisions made:** <bullets, or "none">
- **Follow-ups:** <anything discovered that is out of scope, or "none">
```

## What this skill does NOT do

- No `git commit` / `git push` unless the user asks (the `commit-commands` plugin or `/commit` covers that).
- No GitHub replies or thread resolution.
- No re-planning. If the plan is wrong enough that you'd need to redesign, stop and say so — the fix is a new `/plan-task`, not a silent rewrite.

## Ending your turn

Reply with: plan file path and final status, the step summary line, verification results, deviations, and any follow-ups or blockers. Do not offer to commit.

$ARGUMENTS
