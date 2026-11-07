#!/usr/bin/env bash
# Apply this machine's darwin configuration using identity.local.nix.
set -euo pipefail
export PATH="/nix/var/nix/profiles/default/bin:${PATH:-}"
# shellcheck disable=SC1091
[[ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]] && . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
# shellcheck disable=SC1091
source "$(dirname "$0")/lib-identity.sh"

ROOT="$(_identity_root)"
HOST="$(_identity_get hostName)"

echo "Switching ${ROOT}#${HOST} ..."
exec sudo darwin-rebuild switch --flake "${ROOT}#${HOST}" "$@"
