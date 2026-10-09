#!/usr/bin/env bash
# Usage: commit-index.sh <message> <command...>, run where ./index is a checkout of the index branch and INDEX_TOKEN can push to it.
# Runs the index build, commits and pushes; when another job pushed first, it rebuilds from the new state, never force-pushing.
set -euo pipefail

message="$1"
shift
auth="AUTHORIZATION: basic $(printf 'x-access-token:%s' "$INDEX_TOKEN" | base64 --wrap=0)"

for attempt in 1 2 3 4 5; do
  "$@"
  git -C index add --all site
  if git -C index diff --cached --quiet; then
    echo "The index did not change."
    exit 0
  fi
  git -C index -c user.name="$HUB_BOT_LOGIN" -c user.email="$HUB_BOT_LOGIN@users.noreply.github.com" commit --quiet --message "$message"
  if git -C index -c "http.https://github.com/.extraheader=$auth" push --quiet origin HEAD:refs/heads/index; then
    exit 0
  fi
  echo "The index branch moved; rebuilding from it (attempt $attempt)."
  git -C index fetch --quiet --depth 1 origin index
  git -C index reset --quiet --hard FETCH_HEAD
done

echo "::error::The index could not be pushed after 5 attempts."
exit 1
