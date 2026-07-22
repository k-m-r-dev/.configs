{ lib, pkgs, ... }:
{
  # Ollama local LLM service management

  # After every `nix-switch`, check whether the Homebrew Ollama bottle is
  # missing llama-server (a known packaging gap) and self-heal it by pulling
  # the matching binary from the official GitHub release.
  home.activation.ollamaRepairLlamaServer = lib.hm.dag.entryAfter [ "installPackages" ] ''
    brew_bin=""
    if [ -x "/opt/homebrew/bin/brew" ]; then
      brew_bin="/opt/homebrew/bin/brew"
    else
      brew_bin="$(command -v brew || true)"
    fi

    if [ -z "$brew_bin" ]; then
      echo "brew not found in activation; skipping ollama llama-server repair"
      exit 0
    fi

    ollama_version=$("$brew_bin" list --versions ollama 2>/dev/null | ${pkgs.gawk}/bin/awk '{print $2}' || true)
    if [ -n "$ollama_version" ]; then
      llama_server_path="/opt/homebrew/Cellar/ollama/$ollama_version/libexec/lib/ollama/llama-server"
      if [ ! -f "$llama_server_path" ]; then
        echo "ollama $ollama_version: llama-server missing — fetching from GitHub release..."
        _tmp=$(mktemp -d)
        curl -fsSL \
          -o "$_tmp/ollama.zip" \
          "https://github.com/ollama/ollama/releases/download/v$ollama_version/Ollama-darwin.zip"
        unzip -q "$_tmp/ollama.zip" -d "$_tmp/ollama"
        mkdir -p "$(dirname "$llama_server_path")"
        cp "$_tmp/ollama/Ollama.app/Contents/Resources/llama-server" "$llama_server_path"
        chmod +x "$llama_server_path"
        rm -rf "$_tmp"
        echo "ollama $ollama_version: llama-server installed at $llama_server_path"
      fi
    fi
  '';

  programs.zsh.initContent = ''
    # Ollama management
    ollama-start() {
      local origin=""
      local origin_provided=0
      local model=""

      while [ "$#" -gt 0 ]; do
        case "$1" in
          --origin)
            if [ -z "$2" ]; then
              echo "Missing value for $1"
              return 1
            fi
            origin="$2"
            origin_provided=1
            shift 2
            ;;
          --model)
            if [ -z "$2" ]; then
              echo "Missing value for --model"
              return 1
            fi
            model="$2"
            shift 2
            ;;
          -h|--help)
            echo "Usage: ollama-start [--origin <origin>] [--model <model-name>]"
            return 0
            ;;
          *)
            echo "Unknown argument: $1"
            echo "Usage: ollama-start [--origin <origin>] [--model <model-name>]"
            return 1
            ;;
        esac
      done

      mkdir -p "$HOME/.ollama"

      if [ "$origin_provided" -eq 1 ]; then
        printf "%s\n" "$origin" > "$HOME/.ollama/allowed-origin"
      else
        rm -f "$HOME/.ollama/allowed-origin"
      fi

      if [ -n "$model" ]; then
        printf "%s\n" "$model" > "$HOME/.ollama/default-model"
      fi

      if pgrep -x ollama > /dev/null; then
        echo "Ollama is already running."
        if [ "$origin_provided" -eq 1 ]; then
          echo "Configured origin: $origin"
        else
          echo "Configured origin: (not set)"
        fi
        [ -n "$model" ] && echo "Configured default model: $model"
      else
        if [ "$origin_provided" -eq 1 ]; then
          OLLAMA_ORIGINS="$origin" nohup ollama serve > "$HOME/.ollama/serve.log" 2>&1 &
        else
          nohup ollama serve > "$HOME/.ollama/serve.log" 2>&1 &
        fi
        echo "Ollama started (PID $!). Log: ~/.ollama/serve.log"
        if [ "$origin_provided" -eq 1 ]; then
          echo "Allowed origin: $origin"
        else
          echo "Allowed origin: (not set)"
        fi
        if [ -f "$HOME/.ollama/default-model" ]; then
          echo "Default model: $(cat "$HOME/.ollama/default-model")"
        fi
      fi
    }

    ollama-stop() {
      if pgrep -x ollama > /dev/null; then
        pkill -x ollama && echo "Ollama stopped."
      else
        echo "Ollama is not running."
      fi
    }

    ollama-status() {
      local configured_origin=""
      local configured_model=""

      if [ -f "$HOME/.ollama/allowed-origin" ]; then
        configured_origin="$(cat "$HOME/.ollama/allowed-origin")"
      fi

      if [ -f "$HOME/.ollama/default-model" ]; then
        configured_model="$(cat "$HOME/.ollama/default-model")"
      fi

      if pgrep -x ollama > /dev/null; then
        echo "Ollama is running (PID $(pgrep -x ollama))."
        echo "Allowed origin: $configured_origin"
        if [ -n "$configured_model" ]; then
          echo "Configured default model: $configured_model"
        else
          echo "Configured default model: (not set)"
        fi
        curl -s http://localhost:11434 && echo
      else
        echo "Ollama is not running."
        echo "Last configured origin: $configured_origin"
        if [ -n "$configured_model" ]; then
          echo "Last configured default model: $configured_model"
        else
          echo "Last configured default model: (not set)"
        fi
      fi
    }
  '';
}
