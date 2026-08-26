#!/usr/bin/env bash
# Reply to a PR review thread and optionally resolve it.
# Usage: reply-thread.sh <thread_id> <body> [--resolve]
#        reply-thread.sh <thread_id> --resolve        (resolve only, no reply)
set -euo pipefail
TID="${1:?thread_id required}"; shift
BODY=""; RESOLVE=0
for a in "$@"; do
  if [[ "$a" == "--resolve" ]]; then RESOLVE=1; else BODY="$a"; fi
done

if [[ -n "$BODY" ]]; then
  gh api graphql -f threadId="$TID" -f body="$BODY" -f query='
    mutation($threadId:ID!,$body:String!){
      addPullRequestReviewThreadReply(input:{pullRequestReviewThreadId:$threadId, body:$body}){
        comment{ url } } }' -q '.data.addPullRequestReviewThreadReply.comment.url'
fi
if [[ "$RESOLVE" == 1 ]]; then
  gh api graphql -f threadId="$TID" -f query='
    mutation($threadId:ID!){
      resolveReviewThread(input:{threadId:$threadId}){ thread{ id isResolved } } }' \
    -q '"resolved: \(.data.resolveReviewThread.thread.isResolved)"'
fi
