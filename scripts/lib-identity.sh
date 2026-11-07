#!/usr/bin/env bash
# Shared helpers for reading identity.local.nix.
# shellcheck shell=bash

_identity_root() {
  local dir
  dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
  printf '%s\n' "$dir"
}

_identity_missing_msg() {
  local root="$1"
  cat <<EOF
Missing identity.local.nix.

Copy the example and track it (flakes only see git-tracked files):
  cp "${root}/identity.example.nix" "${root}/identity.local.nix"
  git add "${root}/identity.local.nix"

See README.md (Setup identity). Do not put private key contents here.
EOF
}

_identity_require() {
  local root
  root="$(_identity_root)"
  if [[ ! -f "${root}/identity.local.nix" ]]; then
    _identity_missing_msg "$root" >&2
    return 1
  fi
  return 0
}

# Print a string attr from identity.local.nix (e.g. hostName, primaryUser).
_identity_get() {
  local attr="$1"
  local root
  root="$(_identity_root)"
  _identity_require || return 1
  # Relative import avoids pure-eval bans on absolute paths.
  (cd "$root" && nix eval --impure --raw --expr "(import ./identity.local.nix).${attr}")
}
