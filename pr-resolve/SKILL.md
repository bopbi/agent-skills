---
name: pr-resolve
description: Post replies to PR review threads and resolve them according to an executed /pr-triage plan. Use after /run-plan has finished a pr-<n>-review plan and the fix is pushed — when the user says "resolve the PR comments", "reply to reviewers", "close the review threads". Previews every reply and asks for confirmation before posting. Fixed threads get "fixed in <sha>" + resolved; not-valid and question threads get the plan's drafted reply but stay open for the reviewer.
metadata:
  author: Bobby Prabowo (bopbi)
  origin: personal
allowed-tools: Read, Grep, Glob, Edit(plan/**), Bash(bash */scripts/reply-thread.sh *), Bash(bash */pr-triage/scripts/fetch-comments.sh *), Bash(gh pr view:*), Bash(gh api graphql *), Bash(git status:*), Bash(git log:*), Bash(git rev-parse:*), Bash(git branch:*), Bash(cat:*), Bash(ls:*), Bash(date:*)
---
# PR resolve — close the loop with reviewers, from the plan

This is the only skill in the set that **writes to GitHub**. It posts nothing without showing you the full list first.

## Step 0 — Load the plan and check state

1. Find the PR for the current branch: `gh pr view --json number,url,headRefOid,state`. Stop if there is no PR or it is merged/closed.
2. Find the matching plan: newest `plan/*-pr-<n>-review.md`. Stop if none — run `/pr-triage` first.
3. Read the plan. Require an `## Execution log` (i.e. `/run-plan` has run). If `Status:` is not `done`, list what's incomplete and stop — never resolve a thread whose fix isn't finished.
4. Confirm the fix is **pushed**: local `git rev-parse HEAD` must equal the PR's `headRefOid`, and `git status --short --branch` must show nothing ahead/uncommitted. If not, stop and say what needs pushing. Reviewers must be able to see the change before its thread is resolved.
5. Re-fetch threads to get current state: `bash <skill-dir>/../pr-triage/scripts/fetch-comments.sh --all`. Skip any thread already resolved by someone else.

`<skill-dir>` is the directory containing this SKILL.md — resolve it from the path your agent loaded this skill from (e.g. `~/.claude/skills/pr-resolve`). `pr-triage` is expected as a sibling install (guaranteed by `install.sh`).

## Step 1 — Build the reply list from the plan's verdicts

| Verdict in plan | Reply | Resolve? |
|---|---|---|
| ✅ valid — fixed | `Fixed in <short-sha>` plus one line on what changed (from the execution log). If the plan noted a suggestion was *applied with modification*, say what differed and why. | yes |
| ⚠️ partially valid — fixed differently | One or two lines: what was done and why not the suggested fix. | yes |
| ❌ not valid | The plan's drafted reply, with `path:line` evidence. Polite, factual. | **no** — the reviewer decides |
| ❓ question | The plan's answer. | **no** |
| 🚫 out of scope | One line: acknowledged, tracked where (issue/plan), why not in this PR. | **no** |
| ⏭ skipped in execution log | Skip entirely; list it for the user. | — |

Use the short SHA of the commit that actually contains the fix (`git log --oneline` on the pushed range), not just HEAD, when they differ.

## Step 2 — Preview and confirm (mandatory)

Print the full table — thread, `path:line`, verdict, reply text verbatim, resolve yes/no — then **ask the user to confirm** before posting anything. Accept edits ("change T3's wording to …", "don't resolve T5"). Nothing is posted until an explicit yes. If the user passed `--dry-run`, stop here.

## Step 3 — Post

For each confirmed row:

```bash
bash <skill-dir>/scripts/reply-thread.sh <thread_id> "<reply>" [--resolve]
```

Post one thread at a time; if one fails, report it and continue with the rest, then list failures at the end. Never resolve a thread you didn't reply to (a silent resolve looks dismissive).

## Step 4 — Record in the plan

Append to the plan file:

```markdown
## Resolution log
- **Posted:** <YYYY-MM-DD>
- T1 ✅ replied + resolved (<comment url>)
- T4 ❌ replied, left open
- T7 ⏭ not posted: <reason>
```

## What this skill does NOT do

- No code changes, no commits, no pushes — the fix must already be pushed.
- No replies to review *summaries* or conversation comments (only inline threads have resolve state). If the plan drafted a reply to one, show it and let the user post it manually.
- No re-requesting review (`gh pr edit --add-reviewer`) unless the user asks.

$ARGUMENTS
