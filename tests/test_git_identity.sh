#!/usr/bin/env bash
# Tests for scripts/git-identity.sh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPT="$ROOT/scripts/git-identity.sh"
PASS=0
FAIL=0

assert_ok() {
  local name="$1"
  shift
  if "$@" >/dev/null 2>&1; then
    echo "PASS: $name"
    PASS=$((PASS + 1))
  else
    echo "FAIL: $name" >&2
    FAIL=$((FAIL + 1))
  fi
}

assert_fail() {
  local name="$1"
  shift
  if "$@" >/dev/null 2>&1; then
    echo "FAIL: $name (expected failure)" >&2
    FAIL=$((FAIL + 1))
  else
    echo "PASS: $name"
    PASS=$((PASS + 1))
  fi
}

assert_contains() {
  local name="$1" haystack="$2" needle="$3"
  if [[ "$haystack" == *"$needle"* ]]; then
    echo "PASS: $name"
    PASS=$((PASS + 1))
  else
    echo "FAIL: $name (missing: $needle)" >&2
    echo "$haystack" >&2
    FAIL=$((FAIL + 1))
  fi
}

assert_not_contains() {
  local name="$1" haystack="$2" needle="$3"
  if [[ "$haystack" == *"$needle"* ]]; then
    echo "FAIL: $name (unexpected: $needle)" >&2
    FAIL=$((FAIL + 1))
  else
    echo "PASS: $name"
    PASS=$((PASS + 1))
  fi
}

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

REPO="$TMP/repo"
mkdir -p "$REPO"
git -C "$REPO" init -q
git -C "$REPO" config user.name "init"
git -C "$REPO" config user.email "init@example.com"

# 1. Reject only -u or only -e
assert_fail "reject only -u" bash "$SCRIPT" "$REPO" -u onlyuser
assert_fail "reject only -e" bash "$SCRIPT" "$REPO" -e only@example.com

# 2. Reject invalid --gpg-signing
assert_fail "reject invalid gpg-signing" bash "$SCRIPT" "$REPO" --gpg-signing maybe

# 3. Set local name/email
assert_ok "set local identity" bash "$SCRIPT" "$REPO" -u kmrfn -e work@example.com
NAME="$(git -C "$REPO" config --local --get user.name)"
EMAIL="$(git -C "$REPO" config --local --get user.email)"
assert_ok "local name is kmrfn" test "$NAME" = "kmrfn"
assert_ok "local email is work@example.com" test "$EMAIL" = "work@example.com"

# 4. No args show: LOCAL present, GLOBAL section not required
OUT="$(bash "$SCRIPT" "$REPO")"
assert_contains "show has LOCAL" "$OUT" "LOCAL"
assert_contains "show has name" "$OUT" "kmrfn"
assert_contains "show has email" "$OUT" "work@example.com"
assert_not_contains "show without --global has no GLOBAL section" "$OUT" $'\nGLOBAL\n'
# Header may include path; ensure GLOBAL identity title is absent
assert_not_contains "no GLOBAL title" "$OUT" "GLOBAL"

# 5. --global show has LOCAL and GLOBAL
OUT_G="$(bash "$SCRIPT" "$REPO" --global)"
assert_contains "global show has LOCAL" "$OUT_G" "LOCAL"
assert_contains "global show has GLOBAL" "$OUT_G" "GLOBAL"

# 6. --more show has OTHER LOCAL; with --global --more also OTHER GLOBAL
git -C "$REPO" config --local core.fileMode false
OUT_M="$(bash "$SCRIPT" "$REPO" --more)"
assert_contains "more has OTHER LOCAL" "$OUT_M" "OTHER LOCAL"
assert_not_contains "more without --global has no OTHER GLOBAL" "$OUT_M" "OTHER GLOBAL"

OUT_MG="$(bash "$SCRIPT" "$REPO" --global --more)"
assert_contains "more+global has OTHER LOCAL" "$OUT_MG" "OTHER LOCAL"
assert_contains "more+global has OTHER GLOBAL" "$OUT_MG" "OTHER GLOBAL"

# Identity keys must not appear under OTHER LOCAL
OTHER_BLOCK="$(printf '%s\n' "$OUT_M" | sed -n '/^OTHER LOCAL$/,/^OTHER GLOBAL$/p')"
if [[ -z "$OTHER_BLOCK" ]]; then
  OTHER_BLOCK="$(printf '%s\n' "$OUT_M" | sed -n '/^OTHER LOCAL$/,$p')"
fi
assert_not_contains "OTHER excludes user.name" "$OTHER_BLOCK" "user.name |"
assert_not_contains "OTHER excludes user.email" "$OTHER_BLOCK" "user.email |"

# 7. Optional path from another cwd
OUTSIDE="$TMP/outside"
mkdir -p "$OUTSIDE"
(
  cd "$OUTSIDE"
  bash "$SCRIPT" "$REPO" -u pathuser -e path@example.com >/dev/null
)
assert_ok "path arg sets name" test "$(git -C "$REPO" config --local --get user.name)" = "pathuser"
assert_ok "path arg sets email" test "$(git -C "$REPO" config --local --get user.email)" = "path@example.com"


# 8. --token alone: script exits 0 without requiring a git repo
assert_ok "token-only outside repo" bash "$SCRIPT" --token kmrfn

# 9. --token empty rejected
assert_fail "reject empty --token" bash "$SCRIPT" --token ""

# 10. zsh wrapper exports GH_TOKEN when --token is used (requires gh + logged-in user)
if command -v gh >/dev/null 2>&1 && command -v zsh >/dev/null 2>&1; then
  WRAP="$ROOT/home/git_identity.zsh"
  GH_OUT="$(
    zsh -c '
      source "$1"
      unset GH_TOKEN
      git-identity --token kmrfn
      if [[ -n "$GH_TOKEN" ]]; then
        echo "TOKEN_SET_OK"
      else
        echo "TOKEN_SET_FAIL"
        exit 1
      fi
    ' zsh "$WRAP" 2>/dev/null
  )" || GH_OUT="TOKEN_SET_FAIL"
  assert_contains "zsh --token sets GH_TOKEN" "$GH_OUT" "TOKEN_SET_OK"

  UE_OUT="$(
    zsh -c '
      source "$1"
      unset GH_TOKEN
      git-identity "$2" -u kmrfn -e work@example.com >/dev/null
      if [[ -n "$GH_TOKEN" ]]; then
        echo "U_E_TOKEN_OK"
      else
        echo "U_E_TOKEN_FAIL"
        exit 1
      fi
    ' zsh "$WRAP" "$REPO" 2>/dev/null
  )" || UE_OUT="U_E_TOKEN_FAIL"
  assert_contains "zsh -u/-e sets GH_TOKEN" "$UE_OUT" "U_E_TOKEN_OK"
else
  echo "SKIP: zsh GH_TOKEN export (gh or zsh missing)"
fi

echo
echo "Results: $PASS passed, $FAIL failed"
[[ "$FAIL" -eq 0 ]]
