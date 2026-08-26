#!/usr/bin/env bash
# Fetch ALL feedback on a PR in one shot, as markdown grouped for triage.
# Usage: fetch-comments.sh [PR_NUMBER] [--all]   (--all includes resolved threads)
set -euo pipefail

PR="${1:-}"; INCLUDE_RESOLVED=0
for a in "$@"; do [[ "$a" == "--all" ]] && INCLUDE_RESOLVED=1; done
[[ "$PR" == "--all" ]] && PR=""
if [[ -z "$PR" ]]; then PR=$(gh pr view --json number -q .number); fi

read -r OWNER REPO < <(gh repo view --json owner,name -q '"\(.owner.login) \(.name)"')

Q='query($owner:String!,$repo:String!,$pr:Int!){
  repository(owner:$owner,name:$repo){ pullRequest(number:$pr){
    title url headRefName baseRefName
    reviewThreads(first:100){ nodes{ id isResolved isOutdated path line startLine
      comments(first:50){ nodes{ databaseId author{login} body createdAt url } } } }
    reviews(first:50){ nodes{ author{login} state body url } }
    comments(first:100){ nodes{ author{login} body createdAt url } }
  } } }'

gh api graphql -f query="$Q" -F owner="$OWNER" -F repo="$REPO" -F pr="$PR" \
| PR="$PR" INCLUDE_RESOLVED="$INCLUDE_RESOLVED" jq -r '
  .data.repository.pullRequest as $p
  | "# PR #\(env.PR // "") \($p.title)\n\($p.url)\nbranch: \($p.headRefName) -> \($p.baseRefName)\n"
  , "## Inline review threads"
  , ( [ $p.reviewThreads.nodes[] | select((env.INCLUDE_RESOLVED=="1") or (.isResolved|not)) ]
      | to_entries[]
      | "\n### T\(.key+1) `\(.value.path):\(if .value.startLine and .value.line and .value.startLine != .value.line then "\(.value.startLine)-\(.value.line)" else (.value.line // .value.startLine // "?") end)`"
        + (if .value.isResolved then " (resolved)" else "" end)
        + (if .value.isOutdated then " (outdated)" else "" end)
        + "\nthread_id: \(.value.id)"
        + ( [ .value.comments.nodes[] | "\n- **@\(.author.login)**: \(.body | gsub("\r";"") | gsub("\n";"\n  "))" ] | join("") )
    )
  , "\n## Review summaries"
  , ( [ $p.reviews.nodes[] | select(.body != "") ] | .[]
      | "- **@\(.author.login)** [\(.state)]: \(.body | gsub("\r";"") | gsub("\n";"\n  "))" )
  , "\n## Conversation comments"
  , ( $p.comments.nodes[]
      | "- **@\(.author.login)**: \(.body | gsub("\r";"") | gsub("\n";"\n  "))" )
'
