#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./scripts/lib.sh
source "$SCRIPT_DIR/lib.sh"

main() {
  : "${TARGET_URL:?TARGET_URL is required}"
  : "${ACTION_PATH:?ACTION_PATH is required}"

  local host_keys="${HOST_KEYS:-}"
  local strict="${STRICT:-true}"
  local actual_keys hardcoded_keys
  # ssh-keyscan expects the comma-separated key types as one -t argument.
  # shellcheck disable=SC2054
  local scan_args=(-t ecdsa,ed25519)

  mkdir -p ~/.ssh

  parse_target_url "$TARGET_URL"
  echo "Detected target host: $PARSED_KNOWN_HOST"

  cp "${ACTION_PATH}/data/known_hosts" ~/.ssh/known_hosts

  if [[ -n "$host_keys" ]]; then
    echo "$host_keys" >> ~/.ssh/known_hosts
  fi

  sort -u ~/.ssh/known_hosts -o ~/.ssh/known_hosts
  chmod 600 ~/.ssh/known_hosts

  if [[ "$strict" == "true" ]]; then
    hardcoded_keys="$(known_host_keys ~/.ssh/known_hosts "$PARSED_KNOWN_HOST")"
    if [[ -n "$hardcoded_keys" ]]; then
      echo "::group::Verifying Host Keys for $PARSED_KNOWN_HOST"
      if [[ -n "$PARSED_PORT" ]]; then
        scan_args+=(-p "$PARSED_PORT")
      fi

      # Continue on error with ssh-keyscan to print friendlier error message.
      actual_keys="$({ ssh-keyscan "${scan_args[@]}" "$PARSED_HOST" 2>/dev/null || true; } | awk '$1 !~ /^#/ && NF >= 3 {print $2,$3}' | sort -u)"

      if [[ -z "$actual_keys" ]]; then
        echo "::error::Could not retrieve any keys for $PARSED_KNOWN_HOST"
        exit 1
      fi

      while read -r key; do
        if ! grep -qF "$key" <<< "$hardcoded_keys"; then
          echo "::error::Unverified host key found for $PARSED_KNOWN_HOST: $key"
          exit 1
        fi
      done <<< "$actual_keys"
      echo "::endgroup::"
    else
      echo "::warning::Host $PARSED_KNOWN_HOST not found in known_hosts. Strict checking will rely on host_keys input."
    fi
  fi
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main "$@"
fi
