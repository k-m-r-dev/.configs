#!/usr/bin/env bash
# Report hook / statusLine / helper commands in Claude Code settings files
# that point at script files which do not exist on disk.
#
# Usage:  bash scripts/check-dangling-hooks.sh [extra-settings-file ...]
#
# Exits 1 if anything dangling is found, 0 otherwise.

set -uo pipefail

FOUND_BAD=0

# Candidate settings files: managed, user, then any project-level ones under $HOME.
collect_files() {
  printf '%s\n' \
    "/Library/Application Support/ClaudeCode/managed-settings.json" \
    "/etc/claude-code/managed-settings.json" \
    "$HOME/.claude/settings.json" \
    "$HOME/.claude/settings.local.json"
  find "$HOME" -maxdepth 5 -path '*/.claude/settings*.json' \
       -not -path '*/plugins/*' 2>/dev/null
  # Hook configs shipped by installed plugins
  find "$HOME/.claude/plugins" -name 'hooks.json' 2>/dev/null
  printf '%s\n' "$@"
}

check_file() {
  local f="$1"
  [ -e "$f" ] || return 0

  # Roots used to resolve ${VAR}-prefixed and relative paths.
  #   settings at <proj>/.claude/settings.json  -> PROJECT_ROOT=<proj>
  #   hooks.json at <plugin>/hooks/hooks.json   -> PLUGIN_ROOT=<plugin>
  PROJECT_ROOT=$(dirname "$(dirname "$f")")
  PLUGIN_ROOT=""
  case "$f" in
    */plugins/*/hooks/hooks.json) PLUGIN_ROOT=$(dirname "$(dirname "$f")") ;;
  esac
  export PROJECT_ROOT PLUGIN_ROOT

  if ! jq empty "$f" 2>/dev/null; then
    echo "  !! INVALID JSON — this silently disables every setting in the file"
    FOUND_BAD=1
    return 0
  fi

  # Pull every command/helper string in the file, regardless of nesting.
  local cmds
  cmds=$(jq -r '
    [ (.. | objects | .command? // empty)
    , .apiKeyHelper?       // empty
    , .otelHeadersHelper?  // empty
    , .awsCredentialExport? // empty
    , .awsAuthRefresh?     // empty
    ] | flatten | .[] | select(type == "string")
  ' "$f" 2>/dev/null)

  [ -z "$cmds" ] && { echo "  (no commands)"; return 0; }

  local any_bad=0
  while IFS= read -r cmd; do
    [ -z "$cmd" ] && continue
    # Extract script-looking paths. Include any leading ${VAR...} so that
    # variable-rooted paths are recognised rather than mistaken for absolute ones.
    echo "$cmd" | grep -oE '(\$\{[A-Za-z_][^}]*\})?(~|/|\./)[^"'"'"' ]*\.(sh|js|mjs|cjs|py|rb|ts)\b' \
    | while IFS= read -r p; do
        case "$p" in
          # ${CLAUDE_PLUGIN_ROOT} resolves to the plugin's own dir — resolve it
          # when we are scanning a file inside that plugin.
          '${CLAUDE_PLUGIN_ROOT}'*)
            if [ -n "$PLUGIN_ROOT" ]; then
              rp="$PLUGIN_ROOT${p#\$\{CLAUDE_PLUGIN_ROOT\}}"
              if [ -e "$rp" ]; then echo "  OK       $p"
              else echo "  MISSING  $p  -> $rp"; echo "BAD" >> "$TMPMARK"; fi
            else
              echo "  SKIP     $p  (plugin-relative, no root)"
            fi
            continue ;;
          # ${CLAUDE_PROJECT_DIR...} and friends resolve to the settings file's project root.
          '${'*)
            rp="$PROJECT_ROOT/$(echo "${p#*\}}" | sed 's#^/##')"
            if [ -e "$rp" ]; then echo "  OK       $p"
            else echo "  MISSING  $p  -> $rp"; echo "BAD" >> "$TMPMARK"; fi
            continue ;;
          '~'*)  p="$HOME${p#\~}" ;;
          './'*) p="$PROJECT_ROOT/${p#./}" ;;
        esac
        if [ -e "$p" ]; then
          echo "  OK       $p"
        else
          echo "  MISSING  $p"
          echo "           in command: $cmd"
          echo "BAD" >> "$TMPMARK"
        fi
      done
  done <<< "$cmds"
}

TMPMARK=$(mktemp)
trap 'rm -f "$TMPMARK"' EXIT

while IFS= read -r f; do
  [ -z "$f" ] && continue
  [ -e "$f" ] || continue
  echo "=== $f"
  check_file "$f"
  echo
done < <(collect_files "$@" | awk '!seen[$0]++')

if [ -s "$TMPMARK" ]; then
  echo "RESULT: dangling references found (see MISSING lines above)."
  exit 1
fi
echo "RESULT: no dangling hook/statusLine references."
exit 0
