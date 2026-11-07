#!/usr/bin/env bash
# Evidence for gap-plan goal requirements that do not need Nix.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck disable=SC1091
source "$ROOT/scripts/lib-identity.sh"
fail=0
ok() { printf 'OK  %s\n' "$*"; }
bad() { printf 'FAIL %s\n' "$*"; fail=1; }

echo "== Step 0 identity files =="
[[ -f "$ROOT/identity.example.nix" ]] && ok "identity.example.nix exists" || bad "identity.example.nix missing"
if git -C "$ROOT" ls-files --error-unmatch identity.local.nix >/dev/null 2>&1; then ok "identity.local.nix is git-tracked"; else bad "identity.local.nix not git-tracked (git add identity.local.nix)"; fi
if [[ -f "$ROOT/identity.local.nix" ]]; then
  ok "identity.local.nix present"
  if command -v nix >/dev/null 2>&1 || [[ -x /nix/var/nix/profiles/default/bin/nix ]]; then
    NIX_BIN="$(command -v nix 2>/dev/null || echo /nix/var/nix/profiles/default/bin/nix)"
    host="$( (cd "$ROOT" && "$NIX_BIN" eval --impure --raw --expr "(import ./identity.local.nix).hostName") 2>/dev/null || true)"
    user="$( (cd "$ROOT" && "$NIX_BIN" eval --impure --raw --expr "(import ./identity.local.nix).primaryUser") 2>/dev/null || true)"
    [[ -n "$host" ]] && ok "identity hostName=$host" || bad "cannot read hostName from identity.local.nix"
    [[ -n "$user" ]] && ok "identity primaryUser=$user" || bad "cannot read primaryUser from identity.local.nix"
    [[ -n "$host" && -f "$ROOT/hosts/${host}/configuration.nix" ]] && ok "hosts/${host} exists" || bad "host dir for identity hostName"
  else
    # Without nix, still require a host dir that matches a common local setup via grep
    grep -q 'hostName' "$ROOT/identity.local.nix" && ok "identity.local.nix has hostName" || bad "identity.local.nix missing hostName"
  fi
else
  bad "identity.local.nix missing (cp identity.example.nix identity.local.nix)"
fi
! grep -q 'primaryUser = "' "$ROOT/flake.nix" && ok "flake.nix has no hard-coded primaryUser" || bad "flake.nix still hard-codes primaryUser"
! grep -q 'id_ed25519_fn\|id_ed25519_mahmudur85' "$ROOT/home/shell.nix" && ok "shell.nix has no hard-coded SSH key basenames" || bad "shell.nix still hard-codes SSH keys"
! grep -q 'kmrfn' "$ROOT/docs/gap-analysis-vs-audacioustux-flakes.md" && ok "gap doc has no #kmrfn" || bad "stale kmrfn in gap doc"
grep -q 'identity.local.nix' "$ROOT/docs/gap-analysis-vs-audacioustux-flakes.md" && ok "gap doc mentions identity.local.nix" || bad "gap doc missing identity.local.nix"

echo "== Steps 1-2 no-regression =="
grep -q 'claude-code' "$ROOT/darwin/homebrew.nix" && ok "claude-code cask gated" || bad "claude-code"
! grep -q 'npm_ensure_latest @anthropic-ai/claude-code' "$ROOT/home/packages.nix" && ok "npm claude removed" || bad "npm claude still present"

echo "== Step 3 skip evidence =="
grep -q 'enable = lib.mkEnableOption "Helix editor"' "$ROOT/modules/features.nix" && ok "helix feature exists (default false)" || bad "helix feature"
grep -q 'skipped for now' "$ROOT/docs/gap-analysis-vs-audacioustux-flakes.md" && ok "Step 3 skip documented" || bad "Step 3 docs"

echo "== Step 4 upgrades =="
grep -q 'nix-direnv.enable = true' "$ROOT/home/shell.nix" && ok "nix-direnv" || bad "nix-direnv"
grep -q 'AWS_PAGER' "$ROOT/home/shell.nix" && ok "AWS_PAGER gated" || bad "AWS_PAGER"
grep -q 'Docker.app/Contents/Resources/bin' "$ROOT/darwin/default.nix" && ok "Docker systemPath" || bad "Docker path"
grep -q 'react-native' "$ROOT/home/shell.nix" && grep -q 'flutter' "$ROOT/home/shell.nix" && ok "mobile oh-my-zsh plugins" || bad "mobile plugins"

echo "== Nix presence =="
if command -v nix >/dev/null 2>&1; then
  ok "nix on PATH ($(nix --version))"
elif [[ -x /nix/var/nix/profiles/default/bin/nix ]]; then
  ok "nix installed at /nix/var/nix/profiles/default/bin/nix ($(/nix/var/nix/profiles/default/bin/nix --version))"
else
  bad "nix not installed yet (blocks Step 5)"
fi

[[ "$fail" -eq 0 ]] && echo "PREFLIGHT PASSED" && exit 0
echo "PREFLIGHT INCOMPLETE"
exit 1
