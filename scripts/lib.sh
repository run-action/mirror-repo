#!/usr/bin/env bash

parse_target_url() {
  local target_url="$1"
  local authority rest

  PARSED_HOST=""
  PARSED_PORT=""
  # Returned to callers that source this file.
  # shellcheck disable=SC2034
  PARSED_KNOWN_HOST=""

  case "$target_url" in
    ssh://*)
      authority="${target_url#ssh://}"
      authority="${authority%%/*}"
      authority="${authority##*@}"
      if [[ "$authority" == \[*\]* ]]; then
        PARSED_HOST="${authority#\[}"
        PARSED_HOST="${PARSED_HOST%%\]*}"
        rest="${authority#*\]}"
        if [[ "$rest" == :* ]]; then
          PARSED_PORT="${rest#:}"
        fi
      elif [[ "$authority" == *:* ]]; then
        PARSED_HOST="${authority%%:*}"
        PARSED_PORT="${authority##*:}"
      else
        PARSED_HOST="$authority"
      fi
      ;;
    *@*:*)
      PARSED_HOST="${target_url#*@}"
      PARSED_HOST="${PARSED_HOST%%:*}"
      ;;
    *://*)
      echo "::error::target_url must use SSH, not another URL scheme" >&2
      return 1
      ;;
    *:*)
      PARSED_HOST="${target_url%%:*}"
      ;;
    *)
      echo "::error::target_url must be an SSH URL, such as git@host:owner/repo.git or ssh://git@host/owner/repo.git" >&2
      return 1
      ;;
  esac

  if [[ -z "$PARSED_HOST" ]]; then
    echo "::error::Could not detect target host from target_url" >&2
    return 1
  fi
  if [[ -n "$PARSED_PORT" && ! "$PARSED_PORT" =~ ^[0-9]+$ ]]; then
    echo "::error::Invalid SSH port in target_url: $PARSED_PORT" >&2
    return 1
  fi

  # Returned to callers that source this file.
  # shellcheck disable=SC2034
  PARSED_KNOWN_HOST="$PARSED_HOST"
  if [[ -n "$PARSED_PORT" ]]; then
    # Returned to callers that source this file.
    # shellcheck disable=SC2034
    PARSED_KNOWN_HOST="[$PARSED_HOST]:$PARSED_PORT"
  fi
}

known_host_keys() {
  local known_hosts_file="$1"
  local host="$2"

  awk -v host="$host" '{ split($1, hosts, ","); for (i in hosts) if (hosts[i] == host) print $2, $3 }' "$known_hosts_file" | sort -u
}

delete_origin_head_symbolic_ref() {
  git symbolic-ref --delete refs/remotes/origin/HEAD 2>/dev/null || true
}
