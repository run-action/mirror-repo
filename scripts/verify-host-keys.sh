#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./scripts/lib.sh
source "$SCRIPT_DIR/lib.sh"
DATA_FILE="$SCRIPT_DIR/../data/known_hosts"

main() {
  local hosts=("github.com" "gitlab.com" "bitbucket.org" "codeberg.org" "sourcehut.org")
  local failed=0
  local actual_keys hardcoded_keys

  for host in "${hosts[@]}"; do
    echo "Checking $host..."

    # Continue on error with ssh-keyscan to print friendlier error message.
    actual_keys=$({ ssh-keyscan -t ecdsa,ed25519 "$host" 2>/dev/null || true; } | awk '$1 !~ /^#/ && NF >= 3 {print $2,$3}' | sort -u)

    hardcoded_keys="$(known_host_keys "$DATA_FILE" "$host")"

    if [[ -z "$actual_keys" ]]; then
      echo "::error::Could not retrieve any keys for $host"
      failed=1
      continue
    fi

    while read -r key; do
      if ! grep -qF "$key" <<< "$hardcoded_keys"; then
        echo "::error::Unverified key found for $host: $key"
        failed=1
      fi
    done <<< "$actual_keys"

    if [[ $failed -eq 0 ]]; then
      echo "OK: All keys for $host are verified."
    fi
  done

  if [[ $failed -eq 1 ]]; then
    exit 1
  fi
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main "$@"
fi
