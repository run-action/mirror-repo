#!/usr/bin/env bats

setup() {
  repo_root="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  lib="$repo_root/scripts/lib.sh"
  tmpdir="$(mktemp -d)"
}

teardown() {
  rm -rf "$tmpdir"
}

@test "delete_origin_head_symbolic_ref does not delete the target branch" {
  cd "$tmpdir"
  git init --bare src.git >/dev/null
  git clone src.git work >/dev/null 2>&1

  cd work
  git config user.email test@example.com
  git config user.name "Test User"
  printf "x\n" > file.txt
  git add file.txt
  git -c core.hooksPath=/dev/null commit -m init >/dev/null
  branch="$(git branch --show-current)"
  git push origin "$branch" >/dev/null 2>&1

  cd "$tmpdir"
  git clone src.git clone >/dev/null 2>&1
  cd clone

  [ "$(git symbolic-ref refs/remotes/origin/HEAD)" = "refs/remotes/origin/$branch" ]

  source "$lib"
  delete_origin_head_symbolic_ref

  run git symbolic-ref refs/remotes/origin/HEAD
  [ "$status" -ne 0 ]
  git show-ref --verify --quiet "refs/remotes/origin/$branch"
}

@test "remote-tracking refs push does not create a HEAD branch after symbolic ref deletion" {
  cd "$tmpdir"
  git init --bare src.git >/dev/null
  git clone src.git work >/dev/null 2>&1

  cd work
  git config user.email test@example.com
  git config user.name "Test User"
  printf "x\n" > file.txt
  git add file.txt
  git -c core.hooksPath=/dev/null commit -m init >/dev/null
  branch="$(git branch --show-current)"
  git push origin "$branch" >/dev/null 2>&1

  cd "$tmpdir"
  git clone src.git clone >/dev/null 2>&1
  git init --bare dst.git >/dev/null

  cd clone
  source "$lib"
  delete_origin_head_symbolic_ref
  git remote add mirror ../dst.git
  git push --force --prune mirror "refs/remotes/origin/*:refs/heads/*" >/dev/null 2>&1

  git --git-dir=../dst.git show-ref --verify --quiet "refs/heads/$branch"
  run git --git-dir=../dst.git show-ref --verify --quiet refs/heads/HEAD
  [ "$status" -ne 0 ]
}
