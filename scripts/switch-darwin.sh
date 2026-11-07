#!/usr/bin/env bash
set -euo pipefail
export PATH="/nix/var/nix/profiles/default/bin:$PATH"
# shellcheck disable=SC1091
[[ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]] && . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
HOST="$(scutil --get LocalHostName 2>/dev/null || hostname -s)"

if [[ ! -e result-darwin ]]; then
  nix build ".#darwinConfigurations.\"${HOST}\".system" -o result-darwin
fi
SYS="$(readlink result-darwin)"
echo "Setting system profile to $SYS ..."
sudo env HOME="$HOME" USER="$USER" PATH="$PATH" nix-env -p /nix/var/nix/profiles/system --set "$SYS"
echo "Activating ..."
sudo env HOME="$HOME" USER="$USER" PATH="$PATH" /nix/var/nix/profiles/system/sw/bin/darwin-rebuild activate
echo "Done."
