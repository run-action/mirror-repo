#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./scripts/lib.sh
source "$SCRIPT_DIR/lib.sh"

main() {
  : "${TARGET_URL:?TARGET_URL is required}"
  : "${SSH_KEY:?SSH_KEY is required}"

  local lfs="${LFS:-false}"
  local strict="${STRICT:-true}"
  local ssh_opts

  eval "$(ssh-agent -s)"
  trap 'ssh-agent -k >/dev/null' EXIT
  ssh-add - <<< "$SSH_KEY"

  if [[ "$strict" == "true" ]]; then
    ssh_opts="-o StrictHostKeyChecking=yes"
  else
    ssh_opts="-o StrictHostKeyChecking=accept-new"
  fi

  ssh_opts="$ssh_opts -o HostKeyAlgorithms=ssh-ed25519,ecdsa-sha2-nistp256"
  ssh_opts="$ssh_opts -o PubkeyAcceptedAlgorithms=ssh-ed25519,ecdsa-sha2-nistp256"
  ssh_opts="$ssh_opts -o ControlMaster=no -o ControlPath=none -o BatchMode=yes"
  export GIT_SSH_COMMAND="ssh $ssh_opts"

  git remote add mirror "$TARGET_URL" 2>/dev/null || git remote set-url mirror "$TARGET_URL"

  delete_origin_head_symbolic_ref

  git push --force --prune mirror \
    "refs/remotes/origin/*:refs/heads/*" \
    "refs/tags/*:refs/tags/*"

  if [[ "$lfs" == "true" ]]; then
    git lfs push --all mirror
  fi
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main "$@"
fi
