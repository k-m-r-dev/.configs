#!/usr/bin/env bash
# Print this Mac's LocalHostName (must match a darwinConfigurations attr).
set -euo pipefail
scutil --get LocalHostName 2>/dev/null || hostname -s
