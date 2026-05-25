#!/usr/bin/env bats

setup() {
  repo_root="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  lib="$repo_root/scripts/lib.sh"
}

parse_url() {
  run bash -c 'source "$1"; if parse_target_url "$2"; then printf "%s|%s|%s\n" "$PARSED_HOST" "${PARSED_PORT:-}" "$PARSED_KNOWN_HOST"; else exit $?; fi' _ "$lib" "$1"
}

@test "parses scp-style SSH URL" {
  parse_url "git@codeberg.org:user/repo.git"

  [ "$status" -eq 0 ]
  [ "$output" = "codeberg.org||codeberg.org" ]
}

@test "parses ssh URL with user" {
  parse_url "ssh://git@codeberg.org/user/repo.git"

  [ "$status" -eq 0 ]
  [ "$output" = "codeberg.org||codeberg.org" ]
}

@test "parses ssh URL without user" {
  parse_url "ssh://codeberg.org/user/repo.git"

  [ "$status" -eq 0 ]
  [ "$output" = "codeberg.org||codeberg.org" ]
}

@test "parses ssh URL with port" {
  parse_url "ssh://git@codeberg.org:2222/user/repo.git"

  [ "$status" -eq 0 ]
  [ "$output" = "codeberg.org|2222|[codeberg.org]:2222" ]
}

@test "rejects non-SSH URL schemes" {
  parse_url "https://codeberg.org/user/repo.git"

  [ "$status" -ne 0 ]
  [[ "$output" == *"target_url must use SSH"* ]]
}

@test "rejects invalid SSH port" {
  parse_url "ssh://git@codeberg.org:not-a-port/user/repo.git"

  [ "$status" -ne 0 ]
  [[ "$output" == *"Invalid SSH port"* ]]
}
