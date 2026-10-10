#!/usr/bin/env bash
# Usage: commit-index.sh <message> <command...>, run where ./index is a checkout of the index branch and INDEX_TOKEN can push to it.
# Runs the index build without INDEX_TOKEN, commits and pushes; when another job pushed first, it rebuilds from the new state, never
# force-pushing.
set -euo pipefail

message="$1"
shift

push() {
  # shellcheck disable=SC2016 # the credential helper reads the token when git runs it
  GIT_CONFIG_COUNT=2 \
    GIT_CONFIG_KEY_0=credential.helper GIT_CONFIG_VALUE_0="" \
    GIT_CONFIG_KEY_1=credential.helper \
    GIT_CONFIG_VALUE_1='!f() { if [ "$1" = get ]; then echo username=x-access-token; echo "password=$INDEX_TOKEN"; fi; }; f' \
    git -C index push --quiet origin HEAD:refs/heads/index
}

for attempt in 1 2 3 4 5; do
  env -u INDEX_TOKEN "$@"
  git -C index add --all site
  if git -C index diff --cached --quiet; then
    echo "The index did not change."
    exit 0
  fi
  git -C index -c user.name="$HUB_BOT_LOGIN" -c user.email="$HUB_BOT_LOGIN@users.noreply.github.com" commit --quiet --message "$message"
  if push; then
    exit 0
  fi
  echo "The index branch moved; rebuilding from it (attempt $attempt)."
  git -C index fetch --quiet --depth 1 origin index
  git -C index reset --quiet --hard FETCH_HEAD
done

echo "::error::The index could not be pushed after 5 attempts."
exit 1
