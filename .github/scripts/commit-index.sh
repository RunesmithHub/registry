#!/usr/bin/env bash
# Usage: commit-index.sh <message> <command...>, run where ./index is a checkout of the index branch. Pushes with the deploy key in
# INDEX_DEPLOY_KEY when it is set, and otherwise with INDEX_TOKEN. Runs the index build without either, commits and pushes; when another
# job pushed first, it rebuilds from the new state, never force-pushing.
set -euo pipefail

message="$1"
shift

github_host_key="github.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl"
ssh_folder=""
trap 'if [ -n "$ssh_folder" ]; then rm -rf "$ssh_folder"; fi' EXIT

push() {
  if [ -n "${INDEX_DEPLOY_KEY:-}" ]; then
    if [ -z "$ssh_folder" ]; then
      ssh_folder="$(umask 077 && mktemp -d)"
      (umask 077 && printf '%s\n' "$INDEX_DEPLOY_KEY" > "$ssh_folder/key")
      printf '%s\n' "$github_host_key" > "$ssh_folder/known_hosts"
    fi
    GIT_SSH_COMMAND="ssh -i $ssh_folder/key -o IdentitiesOnly=yes -o StrictHostKeyChecking=yes -o UserKnownHostsFile=$ssh_folder/known_hosts" \
      git -C index push --quiet "git@github.com:$GITHUB_REPOSITORY.git" HEAD:refs/heads/index
    return
  fi

  # shellcheck disable=SC2016 # the credential helper reads the token when git runs it
  GIT_CONFIG_COUNT=2 \
    GIT_CONFIG_KEY_0=credential.helper GIT_CONFIG_VALUE_0="" \
    GIT_CONFIG_KEY_1=credential.helper \
    GIT_CONFIG_VALUE_1='!f() { if [ "$1" = get ]; then echo username=x-access-token; echo "password=$INDEX_TOKEN"; fi; }; f' \
    git -C index push --quiet origin HEAD:refs/heads/index
}

for attempt in 1 2 3 4 5; do
  env -u INDEX_TOKEN -u INDEX_DEPLOY_KEY "$@"
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
