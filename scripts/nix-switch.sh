#!/usr/bin/env bash
# Apply the darwin configuration for this Mac's LocalHostName.
set -euo pipefail
export PATH="/nix/var/nix/profiles/default/bin:${PATH:-}"
# shellcheck disable=SC1091
[[ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]] && . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
HOST="$(scutil --get LocalHostName 2>/dev/null || hostname -s)"

echo "Switching ${ROOT}#${HOST} ..."
exec sudo darwin-rebuild switch --flake "${ROOT}#${HOST}" "$@"
