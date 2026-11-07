#!/usr/bin/env bash
# Print hostName from identity.local.nix (for flake attr selection).
set -euo pipefail
# shellcheck disable=SC1091
source "$(dirname "$0")/lib-identity.sh"
_identity_get hostName
