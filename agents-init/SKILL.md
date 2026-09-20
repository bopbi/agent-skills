---
name: agents-init
description: Initialize or convert a project's agent guide files. Creates a canonical AGENTS.md and relative symlinks for CLAUDE.md, GEMINI.md, COPILOT.md, and .github/copilot-instructions.md so the project works with multiple AI coding providers. Triggers on "/agents-init", "init agent guide", "make this project work with Claude/Gemini/Copilot".
metadata:
  author: Bobby Prabowo (bopbi)
  origin: personal
allowed-tools: Read, Grep, Glob, Write, Edit, Bash(cat:*), Bash(head:*), Bash(tail:*), Bash(sed -n:*), Bash(ls:*), Bash(find:*), Bash(grep:*), Bash(rg:*), Bash(wc:*), Bash(tree:*), Bash(test:*), Bash(readlink:*), Bash(ln:*), Bash(mv:*), Bash(mkdir:*), Bash(rm:*), Bash(diff:*), Bash(git status:*), Bash(git log:*), Bash(git diff:*), Bash(git show:*), Bash(git blame:*), Bash(git branch:*), Bash(npm:*), Bash(yarn:*), Bash(pnpm:*), Bash(bun:*), Bash(pip:*), Bash(poetry:*), Bash(pytest:*), Bash(make:*), Bash(cargo:*), Bash(go:*), Bash(mvn:*), Bash(gradle:*), Bash(bundle:*), Bash(rake:*), Bash(gem:*), Bash(composer:*), Bash(php:*), Bash(dotnet:*)
---
# Agents-init — set up canonical agent guide files

When starting work in a new repo (or cleaning up an existing one), set up the project's guide files so every major AI coding agent reads the same instructions from a single canonical source.

This skill creates `AGENTS.md` as the canonical file and symlinks `CLAUDE.md`, `GEMINI.md`, `COPILOT.md`, and `.github/copilot-instructions.md` to it. If guide files already exist, it converts them to this layout safely.

## Hard rules

1. **Never delete or overwrite guide content without showing it to the user first.** Content lives in the canonical `AGENTS.md`; duplicates are removed only when their content is known to be identical or the user has explicitly chosen the canonical file.
2. **Always use relative symlinks.** From the repo root: `ln -s AGENTS.md CLAUDE.md`. For `.github/copilot-instructions.md`: `ln -s ../AGENTS.md .github/copilot-instructions.md`. Absolute symlinks break when the repo is cloned elsewhere.
3. **Never overwrite a real file** (a regular file, not a symlink) **without the conflict-ask flow.** If multiple real guide files exist with different content, stop and ask which is canonical.
4. **No git mutations** in the target project. Use plain `mv`, `rm`, and `ln`; do not run `git mv`, `git add`, `git commit`, or push.
5. **Idempotent.** Re-running on an already-correct layout must report "already ok" and change nothing.
6. **Windows warning.** On Windows, symlinks require `core.symlinks=true` or Developer Mode. If `ln -s` fails, stop and explain rather than silently copying.

## Detection

Check these five paths, relative to the project root:

- `AGENTS.md`
- `CLAUDE.md`
- `GEMINI.md`
- `COPILOT.md`
- `.github/copilot-instructions.md`

For each path, classify it as one of:

- **Missing** — `test -e <path>` is false.
- **Regular file** — `test -f <path>` is true and `test -L <path>` is false.
- **Symlink** — `test -L <path>` is true. Use `readlink <path>` to see its target.

A symlink whose target is not the expected relative path (`AGENTS.md` for the four root files, `../AGENTS.md` for the `.github` file) is treated as a conflict (State F).

## State machine

After detection, the project is in exactly one of these states. Handle it, then move to Symlink creation and Verification.

### State A — Nothing exists

No guide files exist at any of the five paths.

1. Explore the project to learn its build/test/lint commands, directory layout, conventions, and any existing contribution docs.
2. Write a fresh `AGENTS.md` that captures the essential context an AI agent needs.
3. Run the **Symlink creation** step.

### State B — Exactly one real file

Only one of the five paths is a regular file; the rest are missing or already correct symlinks.

1. If the real file is not already at `AGENTS.md`, run `mv <file> AGENTS.md`.
2. Run the **Symlink creation** step.

### State C — Multiple real files, identical content

Two or more regular files exist and their contents are identical (verify with `diff -q` or `cmp -s`).

1. Keep the file at `AGENTS.md` if one is already there; otherwise `mv` one of the duplicates to `AGENTS.md`.
2. Remove the now-redundant real duplicates with `rm`.
3. Run the **Symlink creation** step.

### State D — Multiple real files, different content

Two or more regular files exist with differing content.

1. **Stop.** Do not move, remove, or overwrite anything yet.
2. Show the user each conflicting file path and a summary of its content (use `head`, `cat`, or `diff` as needed).
3. Ask: "Which file should become the canonical `AGENTS.md`? I can carry over unique sections from the others before replacing them with symlinks."
4. After the user picks the canonical file, `mv` it to `AGENTS.md` (if not already there), then run the **Symlink creation** step for the remaining paths.

### State E — Already symlinked correctly

All existing paths are correct:

- `AGENTS.md` is a regular file.
- `CLAUDE.md`, `GEMINI.md`, and `COPILOT.md` are symlinks pointing to `AGENTS.md`.
- `.github/copilot-instructions.md` is a symlink pointing to `../AGENTS.md`.

Report "already ok" and do nothing.

### State F — A symlink points elsewhere

A path is a symlink but does not point to the expected relative target.

1. Show the symlink path and its actual `readlink` target.
2. Ask: "This symlink does not point to the canonical `AGENTS.md`. Repoint it, or leave it alone?"
3. If the user chooses to repoint, remove the old symlink with `rm` and create the correct one in the **Symlink creation** step.

## AGENTS.md authoring guidance

When writing a fresh `AGENTS.md` (State A), investigate the project first:

- Read `README.md`, `CONTRIBUTING.md`, and the main manifest (`package.json`, `pyproject.toml`, `Cargo.toml`, `go.mod`, `Makefile`, etc.).
- Identify build, test, lint, and typecheck commands (e.g., `npm test`, `pytest`, `cargo test`, `make test`, `tsc --noEmit`).
- Note directory conventions: source, tests, docs, configuration, and generated outputs.
- Capture project-specific rules: coding style, branch naming, release process, and any model-tier or agent-policy files.
- Keep the guide concise but complete enough that an AI agent can make correct first guesses.

## Symlink creation

Create the four provider-specific symlinks from the project root, using relative targets:

```bash
ln -s AGENTS.md CLAUDE.md
ln -s AGENTS.md GEMINI.md
ln -s AGENTS.md COPILOT.md
mkdir -p .github
ln -s ../AGENTS.md .github/copilot-instructions.md
```

For each path:

- If it is missing, create the symlink.
- If it is already the correct symlink, skip it.
- If it is an incorrect symlink, handle it via State F.
- If it is a regular file, it should have been resolved earlier (State B/C/D); do not overwrite it here without asking.

## Verification

After any changes, re-check each of the five paths:

1. `AGENTS.md` exists and is a regular file (`test -f AGENTS.md && ! test -L AGENTS.md`).
2. `CLAUDE.md`, `GEMINI.md`, and `COPILOT.md` are symlinks whose `readlink` target is `AGENTS.md`.
3. `.github/copilot-instructions.md` is a symlink whose `readlink` target is `../AGENTS.md`.
4. Reading each symlink yields the same content as `AGENTS.md` (e.g., `diff -q AGENTS.md CLAUDE.md` reports no differences).

If any check fails, report the failure explicitly and do not mark the task complete.

## Output shape

End with a summary table:

| Path | Result |
|---|---|
| `AGENTS.md` | created / present as canonical / unchanged |
| `CLAUDE.md` | symlinked / already ok / skipped |
| `GEMINI.md` | symlinked / already ok / skipped |
| `COPILOT.md` | symlinked / already ok / skipped |
| `.github/copilot-instructions.md` | symlinked / already ok / skipped |

Also state the overall outcome, for example:

- "Wrote fresh `AGENTS.md` and created four symlinks."
- "Converted existing `CLAUDE.md` to canonical `AGENTS.md` and symlinked the rest."
- "Multiple guide files conflict — waiting for you to choose the canonical file."
- "Layout already correct; no changes made."

$ARGUMENTS
