#!/usr/bin/env bash
# Post-switch verification for docs/gap-analysis-vs-audacioustux-flakes.md Step 5.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck disable=SC1091
source "$ROOT/scripts/lib-identity.sh"
export PATH="/etc/profiles/per-user/$(whoami)/bin:/run/current-system/sw/bin:/opt/homebrew/bin:/nix/var/nix/profiles/default/bin:$PATH"
# shellcheck disable=SC1091
[[ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]] && . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh

fail=0
ok() { printf 'OK  %s\n' "$*"; }
bad() { printf 'FAIL %s\n' "$*"; fail=1; }
have() { command -v "$1" >/dev/null 2>&1; }

EXPECTED_USER="$(_identity_get primaryUser)"
EXPECTED_HOST="$(_identity_get hostName)"
FLAKE_ATTR="${FLAKE_ATTR:-$EXPECTED_HOST}"

echo "== identity =="
user="$(whoami)"
host="$(scutil --get LocalHostName 2>/dev/null || hostname)"
[[ "$user" == "$EXPECTED_USER" ]] && ok "whoami=$user" || bad "whoami=$user (expected $EXPECTED_USER)"
[[ "$host" == "$EXPECTED_HOST" ]] && ok "LocalHostName=$host" || bad "LocalHostName=$host (expected $EXPECTED_HOST)"

echo "== nix =="
if have nix; then ok "nix=$(nix --version)"; else bad "nix not on PATH"; fi

echo "== flake attribute =="
if have nix; then
  eval_host="$(
    (cd "$ROOT" && nix eval --raw ".#darwinConfigurations.\"${FLAKE_ATTR}\".config.networking.hostName") 2>/dev/null || true
  )"
  if [[ "$eval_host" == "$EXPECTED_HOST" ]]; then
    ok "darwinConfigurations.${FLAKE_ATTR} hostName=$eval_host"
  else
    bad "cannot eval darwinConfigurations.${FLAKE_ATTR} (got '${eval_host}')"
  fi
fi

echo "== system profile =="
if [[ -L /run/current-system ]]; then
  ok "current-system=$(readlink /run/current-system)"
  profile_target="$(readlink "/nix/var/nix/profiles/$(readlink /nix/var/nix/profiles/system)" 2>/dev/null || true)"
  current_target="$(readlink /run/current-system)"
  if [[ -n "$profile_target" && "$profile_target" == "$current_target" ]]; then
    ok "profile matches current-system"
  else
    bad "profile ($profile_target) != current-system ($current_target) — run scripts/switch-darwin.sh"
  fi
else
  bad "/run/current-system missing"
fi

echo "== commands (enabled features) =="
for cmd in docker op lean-ctx zellij rustup; do
  if have "$cmd"; then ok "$cmd=$(command -v "$cmd")"; else bad "$cmd missing from PATH"; fi
done

echo "== existing mobile/dev paths =="
if [[ -d "$HOME/fvm" || -d "$HOME/.pub-cache" ]]; then ok "FVM/pub-cache present"; else bad "FVM/pub-cache missing"; fi
# Appium: ~/.appium is created by HM activation; inspector cask is Gatekeeper-disabled upstream.
if [[ -d "$HOME/.appium" || -d "$HOME/.appium2" || -d "$HOME/.appium3" ]] || have appium; then
  ok "Appium runtime present"
elif [[ -f "$ROOT/home/appium.nix" ]] && grep -q 'appium.nix' "$ROOT/home/default.nix"; then
  ok "Appium module configured (home/appium.nix); inspector cask disabled by Homebrew Gatekeeper"
else
  bad "Appium not found"
fi

echo "== deferred features =="
if have aws; then bad "aws present unexpectedly"; else ok "aws absent (deferred)"; fi
if have hx; then bad "helix present unexpectedly"; else ok "helix absent (deferred)"; fi

if [[ "$fail" -eq 0 ]]; then echo "ALL CHECKS PASSED"; exit 0; fi
echo "SOME CHECKS FAILED"; exit 1
