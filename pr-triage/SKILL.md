---
name: pr-triage
description: Triage ALL review comments on a GitHub PR and write a plan file (plan/<date>-pr-<n>-review.md) — no code changes. Fetches every inline thread, review summary, and conversation comment, judges whether each comment is valid against the actual code, groups them by common theme (not by order), and writes a resolution plan with a model recommendation. Use when the user says "plan the PR comments", "triage review feedback", "check if the reviewer is right", or runs it on a branch that has an open PR after pushing. Run with no arguments from the PR branch; a PR number is optional. Never edits code, never replies, never commits.
metadata:
  author: Bobby Prabowo (bopbi)
  origin: personal
allowed-tools: Read, Grep, Glob, Write(plan/**), Edit(plan/**), Bash(mkdir -p plan:*), Bash(date:*), Bash(bash */scripts/fetch-comments.sh *), Bash(gh pr view:*), Bash(gh pr diff:*), Bash(gh api:*), Bash(cat:*), Bash(head:*), Bash(tail:*), Bash(sed -n:*), Bash(ls:*), Bash(find:*), Bash(grep:*), Bash(rg:*), Bash(wc:*), Bash(tree:*), Bash(git status:*), Bash(git log:*), Bash(git diff:*), Bash(git show:*), Bash(git blame:*), Bash(git branch:*), Bash(git rev-parse:*), Agent(Explore)
---
# Plan PR review — read everything, judge it, write the plan, change nothing

Reviewers comment in diff order, not importance order, and several comments usually share one root cause. This skill reads **all** feedback first, checks each comment against the real code, clusters by theme, and writes a plan file the user reviews in their editor. It does **not** implement anything.

## Hard rules

1. **Write only inside `plan/`.** No code edits, no other files. Create `plan/` if missing.
2. **No GitHub side effects.** No replies, no resolving threads, no `git commit`/`push`/`add`. Do not touch `.gitignore`.
3. **Do not enter plan mode** (`EnterPlanMode`) — the file is the plan.
4. **Do not start implementing** or offer to. End with the file path and a short summary.

## Arguments

Normally run with **no arguments** from the PR's branch — the PR is resolved from the current branch via `gh pr view`. `$ARGUMENTS` may optionally contain `--all` (include resolved threads), free-text guidance (e.g. "ignore style nits"), or a PR number/URL to override the branch lookup (rare).

## Step 0 — Confirm which PR and that it's up to date

```bash
gh pr view --json number,title,url,headRefName,headRefOid,baseRefName,state
git rev-parse HEAD && git status --short --branch
```

- If `gh pr view` reports no PR for this branch, stop and tell the user (don't guess a number).
- If `headRefOid` ≠ local `HEAD`, or `git status` shows the branch is ahead of its upstream, the reviewers commented on a different commit than what's checked out — say so up front and note that some threads may be outdated.
- If the PR state is `MERGED`/`CLOSED`, mention it and continue only if the user asked.

## Step 1 — Fetch everything (one command)

```bash
bash <skill-dir>/scripts/fetch-comments.sh [--all]
```

`<skill-dir>` is the directory containing this SKILL.md — resolve it from the path your agent loaded this skill from (e.g. `~/.claude/skills/pr-triage`).

(Uses the current branch's PR; pass a number first only if the user gave one.)

Prints all feedback as markdown with inline threads labelled `T1`, `T2`, … (file:line, thread_id, every comment). Read the **whole** output before anything else. Fallback if it fails: `gh pr view <n> --comments` and `gh api repos/{owner}/{repo}/pulls/<n>/comments`.

Also run `gh pr diff --name-only` to know the PR's scope.

## Step 2 — Validate each comment against the code

For every thread, open the referenced file/lines and decide:

| Verdict | Meaning |
|---|---|
| ✅ **valid** | The reviewer is right; the code has the issue described. |
| ⚠️ **partially valid** | Real concern, but the suggested fix is wrong/overkill, or it only applies to some sites. |
| ❌ **not valid** | The comment is mistaken (misread the code, already handled, contradicts project convention, or would break something). Cite the evidence. |
| ❓ **question / unclear** | Needs an answer, not a change — or you can't determine validity without the user. |
| 🚫 **out of scope** | Legitimate but belongs in a separate PR. |

**Suggested changes.** A comment containing a ` ```suggestion ` block is a concrete proposed replacement for the thread's line range (`path:start-end` in the fetch output; a single number means one line). Treat it as a proposal to evaluate, not an instruction: compare it against the current code and record one of — *apply as-is*, *apply with modification* (say what and why), or *reject* (say why). Check that it still fits if the lines have moved since the reviewer's commit (the thread will be marked `outdated`).

Be evidence-based, not deferential: a reviewer being senior or a bot being confident does not make a comment valid. Equally, don't dismiss a comment just because the fix is inconvenient. Cite `path:line` for every verdict. If two reviewers conflict, or a ⚠️ partial has more than one reasonable fix, that is a **decision**: ask the user now (one question, options with trade-offs) rather than leaving it for execution. Only if the user explicitly defers does it go into "Needs your decision", with the threads it blocks. Anything you couldn't verify but can default sensibly is an **assumption** — state the default and its fallback, don't ask.

## Step 3 — Cluster by root cause, ignoring order

Group threads that share a cause or pattern (same bug at multiple call sites → fix once at source; repeated naming/error-handling pattern → one sweep; questions; disputed). A thread can only belong to one cluster.

## Step 4 — Write the plan file

Path: `plan/<YYYY-MM-DD>-pr-<n>-review.md` (`date +%F`). If one already exists for this PR, update it in place and note what changed.

```markdown
# PR #<n> review plan — <PR title>

- **Status:** draft
- **Created:** <YYYY-MM-DD>
- **PR:** <url> (<head> → <base>)
- **Threads:** <total> total, <valid> valid, <partial> partial, <invalid> not valid, <question> question, <oos> out of scope

## Triage table
| Thread | Location | Reviewer | Summary | Verdict | Cluster |
|---|---|---|---|---|---|
| T1 | `api/client.ts:42` | @alice | rename getData | ✅ valid | Naming |
| T3 | `api/client.ts:50-58` | @alice | suggestion: early return | ✅ valid (apply as-is) | Error handling |
| T2 | `api/client.ts:60` | @bob | wrap in Result | ⚠️ partial | Error handling |
| T4 | `ui/List.tsx:10` | @copilot | possible null | ❌ not valid | — |

## Verdict details
One short entry per non-✅ thread (and per ✅ thread when the reason isn't obvious): why, with `path:line` evidence. For ❌ include the suggested reply wording the user can paste.

## Clusters & steps
### Cluster: <name> — threads T2, T5, T9
Root cause, chosen approach, then ordered concrete steps with file paths.

## Assumptions
Stated defaults with fallbacks for anything not verifiable from the code. (Not questions.)

## Needs your decision
Only decisions the user explicitly deferred while triaging. Each names the threads/clusters it blocks and leaves a line for the answer:
- **D1.** <question> — options: A (…) / B (…). Blocks T2, T5 (cluster "Error handling").
  → Decision:

## Non-goals
🚫 out-of-scope items, and what you're deliberately not doing.

## Verification
Tests/lint/typecheck to run for the touched areas; any test that should be added per a comment.

## Model recommendation
- **Overall tier:** <small | standard | large | frontier> — one sentence why.
- **Compatible model range:** List every provider/model entry from the canonical policy row matching the overall tier.
- **Per cluster (only where it differs):** e.g. "Error handling → large — compatible model range: list every provider/model entry from the matching row."
- **Execution compatibility:** Any listed model, or a verified higher-tier model, is acceptable even when it differs from the model used to create the plan. Record the actual provider, model, and tier in the execution log.
```

### Choosing the model recommendation

The user wants to conserve spend. Recommend the **cheapest tier that can reliably execute each cluster**, judged by the cluster's *ambiguity and blast radius* — not by how important the feature is or how loud the reviewer was.

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
| large | cross-cutting or ambiguous: shared state, concurrency, unfamiliar code | `claude-opus-5` | `gpt-5.6-sol` | `gemini-3.8-flash` | `kimi-k3` (long-context variant: `kimi-k3-256k`) | `qwen3.8-max` | `grok-4.6` |
| frontier | genuinely hard and costly to get wrong | `claude-fable-5-1` | `gpt-5.5-pro` | `gemini-3.8-flash` (no higher general-purpose production API model) | `kimi-k3` with `reasoning_effort: "max"` (no separate frontier model; long-context variant: `kimi-k3-256k`) | `qwen3.8-max` (no higher general-purpose production API model) | `grok-4.6` (no higher general-purpose production API model) |

Model IDs are current as of **September 2026**. Providers ship often, so
verify current availability before relying on an exact ID. Default to
**standard** unless work is fully mechanical (small) or cross-cutting or
ambiguous (large); use frontier only when large is insufficient and mistakes
would be unusually costly.
<!-- END GENERATED MODEL-TIER POLICY -->

Rules:
- When clusters vary, give the per-cluster split so the user can run cheap parts on a cheap model and switch only for the hard ones.
- A user may switch providers between planning and execution if the execution model is listed for, or is verified above, the required tier.
- A well-written plan *lowers* the tier needed — if something needs *large* mainly because the plan is vague, tighten the plan instead.
- If the whole plan is small and mechanical, say so plainly: "small for everything."

## Ending your turn

Reply with the plan file path, the thread counts by verdict, the cluster names, and — if any — the deferred decisions (D1, D2…) that must be answered in the file before `/run-plan` will start. No "shall I implement this?".

## Token discipline
One fetch, one read per file. Don't re-fetch or re-read between clusters. Use `Explore` only when a thread references code you haven't loaded; never one agent per comment.

$ARGUMENTS
