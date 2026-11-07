#!/usr/bin/env bash
set -euo pipefail
export PATH="/nix/var/nix/profiles/default/bin:$PATH"
# shellcheck disable=SC1091
[[ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]] && . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
# shellcheck disable=SC1091
source "$(dirname "$0")/lib-identity.sh"

ROOT="$(_identity_root)"
cd "$ROOT"
HOST="$(_identity_get hostName)"

if [[ ! -e result-darwin ]]; then
  nix build ".#darwinConfigurations.\"${HOST}\".system" -o result-darwin
fi
SYS="$(readlink result-darwin)"
echo "Setting system profile to $SYS ..."
sudo env HOME="$HOME" USER="$USER" PATH="$PATH" nix-env -p /nix/var/nix/profiles/system --set "$SYS"
echo "Activating ..."
sudo env HOME="$HOME" USER="$USER" PATH="$PATH" /nix/var/nix/profiles/system/sw/bin/darwin-rebuild activate
echo "Done. Verify: ~/.config/nix/scripts/verify-gap-step5.sh"
