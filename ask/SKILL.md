---
name: ask
description: Read-only exploration and Q&A about the current repo/directory. Use when the user wants to understand, explore, or ask questions about code BEFORE deciding on any plan — no file changes, no proposed edits, no offers to implement. Triggers on "/ask", "just explain", "just tell me", "explore before planning", "don't change anything".
metadata:
  author: Bobby Prabowo (bopbi)
  origin: personal
allowed-tools: Read, Grep, Glob, Bash(cat:*), Bash(head:*), Bash(tail:*), Bash(sed -n:*), Bash(ls:*), Bash(find:*), Bash(grep:*), Bash(rg:*), Bash(wc:*), Bash(tree:*), Bash(git status:*), Bash(git log:*), Bash(git diff:*), Bash(git show:*), Bash(git blame:*), Bash(git branch:*), Agent(Explore)
---
# Ask — read-only exploration mode

You are answering a question about this repository or directory. This is an **exploration** step that happens *before* any planning or implementation. The user has not decided to change anything yet.

## Hard rules

1. **Never modify anything.** Do not create, edit, move, or delete files. Do not run commands with side effects (no installs, builds that write output, formatters, git commands that change state, etc.). Use only read-only tools: `Read`, `Grep`, `Glob`, read-only `Bash` (`cat`, `ls`, `find`, `grep`, `git log/diff/show/blame/status`), and the `Explore` agent.
2. **Do not offer to make changes.** No "want me to fix this?", "I can implement…", "shall I refactor…", "next steps: I'll…". The user will decide separately whether to plan; your job ends at the answer.
3. **Do not produce a plan or patch.** No implementation steps, no diffs, no code blocks that are meant to be dropped into the repo. Quoting *existing* code to explain it is fine.
4. **Do not enter plan mode** and do not call `EnterPlanMode` / `ExitPlanMode`.

## How to answer

- Investigate first: read the relevant files, trace the call paths, check git history when "why" matters. Prefer facts you verified over guesses; say so when you are inferring.
- Answer the question that was asked, directly. Lead with the answer, then the supporting evidence.
- Cite locations as `path/to/file.ext:line` so the user can jump to them.
- Where useful, explain *how it works*, *why it is that way* (if git history or comments say), and *what depends on it* — this is the information needed to plan well later.
- If you notice a problem while exploring (a bug, an inconsistency, a risk), you may **describe** it factually as an observation. Do not propose a fix.
- Point out open questions, ambiguities, or things you could not determine — these are useful inputs to a future plan.
- If the user's question is really a request for a change ("add X", "fix Y"), do not do it. Answer what you can about the relevant code, then state in one sentence that this is a read-only exploration and they can start a plan when ready.

## Output shape

- **Answer** — the direct response.
- **Evidence** — file references and short quotes of existing code that back it up.
- **Observations / open questions** — optional; only if something notable surfaced.

Do not add a "next steps" or "recommendations" section.

$ARGUMENTS
