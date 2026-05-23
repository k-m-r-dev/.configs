{ ... }:
{
  # Ollama local LLM service management
  programs.zsh.initContent = ''
    # Ollama management
    ollama-start() {
      if pgrep -x ollama > /dev/null; then
        echo "Ollama is already running."
      else
        nohup ollama serve > "$HOME/.ollama/serve.log" 2>&1 &
        echo "Ollama started (PID $!). Log: ~/.ollama/serve.log"
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
      if pgrep -x ollama > /dev/null; then
        echo "Ollama is running (PID $(pgrep -x ollama))."
        curl -s http://localhost:11434 && echo
      else
        echo "Ollama is not running."
      fi
    }
  '';
}
