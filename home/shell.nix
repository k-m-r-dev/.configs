{ pkgs, config, ... }:
{
  programs.zsh = {
    enable = true;
    dotDir = "${config.xdg.configHome}/zsh";
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    initContent = ''
      # Source .profile if it exists (for environment variables set in bash profile)
      [[ -f "$HOME/.profile" ]] && source "$HOME/.profile"

      # GPG configuration
      export GPG_TTY=$(tty)

      # Start ssh-agent and add GitHub key if not running/present
      if ! ssh-add -l > /dev/null; then
        ssh-add --apple-use-keychain ~/.ssh/id_ed25519_fn
      fi

      # Load fnm (Fast Node Manager)
      eval "$(fnm env --use-on-cd --shell zsh)"
      export COREPACK_HOME="$HOME/.cache/corepack"
      export PATH="$COREPACK_HOME/bin:$PATH"

      # Enforce Node 24 as the fnm default (required by gsd-pi)
      fnm default 24 >/dev/null 2>&1 || true

      # FVM (Flutter Version Manager) configuration
      export FVM_CACHE_PATH="$HOME/fvm"
      export PATH="$HOME/.pub-cache/bin:$PATH"
      # Optionally use FVM default Flutter version
      if [ -d "$FVM_CACHE_PATH/default/bin" ]; then
        export PATH="$FVM_CACHE_PATH/default/bin:$PATH"
      fi

      # Source AWS Utils
      [[ -f "$HOME/.aws_utils.zsh" ]] && source "$HOME/.aws_utils.zsh"

      # Source NPM Utils, which set NPM token for FN private registry
      [[ -f "$HOME/.npm_utils.zsh" ]] && source "$HOME/.npm_utils.zsh"

      # Source TDG token helper for CF Access credentials
      [[ -f "$HOME/.tdg_token.zsh" ]] && source "$HOME/.tdg_token.zsh"

      # Load NVM (Node Version Manager) - disabled in favor of fnm
      # export NVM_DIR="$HOME/.nvm"
      # unset NPM_CONFIG_PREFIX  # Unset before NVM to avoid conflicts
      # [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
      # [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

      # Bun global installs live here
      export BUN_INSTALL="$HOME/.bun"
      export PATH="$BUN_INSTALL/bin:$PATH"

      # Keep ~/.npm-global/bin on PATH for tools installed via activation hooks
      # (do NOT export NPM_CONFIG_PREFIX here)
      export PATH="$HOME/.npm-global/bin:$PATH"

      # Enable OMP completions when the binary is available
      if command -v omp >/dev/null 2>&1; then
        eval "$(omp completions zsh)"
      fi

      # Added by Antigravity
      export PATH="/Users/khandkermahmudur/.antigravity/antigravity/bin:$PATH"

      # JDK paths (baked in by Nix at build time)
      export JAVA_HOME_11="${pkgs.zulu11}"
      export JAVA_HOME_17="${pkgs.zulu17}"
      export JAVA_HOME="$JAVA_HOME_17"
      export PATH="$JAVA_HOME/bin:$PATH"

      # Switch between Nix-managed JDK versions
      # Usage: use-java 11 | use-java 17
      use-java() {
        local version="''${1:-17}"
        case "$version" in
          11) export JAVA_HOME="$JAVA_HOME_11" ;;
          17) export JAVA_HOME="$JAVA_HOME_17" ;;
          *) echo "Usage: use-java [11|17]"; return 1 ;;
        esac
        export PATH="$JAVA_HOME/bin:$PATH"
        echo "Switched to $(java -version 2>&1 | head -1)"
      }

      # Set ANDROID_HOME for Android SDK (from Android Studio)
      export ANDROID_HOME="$HOME/Library/Android/sdk"
      if [ -d "$ANDROID_HOME" ]; then
        
        export PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$PATH"
        export PATH="$ANDROID_HOME/emulator:$PATH"
        export PATH="$ANDROID_HOME/platform-tools:$PATH"
        export PATH="$ANDROID_HOME/tools:$PATH"
        export PATH="$ANDROID_HOME/tools/bin:$PATH"
        
        # Set ANDROID_NDK_HOME to the latest NDK version
        if [ -d "$ANDROID_HOME/ndk" ]; then
          export ANDROID_NDK_HOME="$(ls -d $ANDROID_HOME/ndk/* 2>/dev/null | tail -n 1)"
          export NDK_HOME="$ANDROID_NDK_HOME"
        fi
      fi

      # Appium configuration
      export APPIUM_HOME="$HOME/.appium"
      export APPIUM_LOG_LEVEL="info"

      # Android bundletool jar path (Homebrew)
      export BUNDLETOOL_PATH="/opt/homebrew/opt/bundletool/libexec/bundletool-all.jar"

      # pipx installs live in ~/.local/bin
      export PATH="$HOME/.local/bin:$PATH"

      # Field Nation local setup script
      export SETUP_PATH="$HOME/Workspace/fieldnation/fn-local-setup/setup.sh"

      # Unalias gsd set by oh-my-zsh git plugin (conflicts with gsd-pi)
      unalias gsd 2>/dev/null || true
    '';

    shellAliases = {
      la = "ls -la";
      ".." = "cd ..";
      "nix-switch" = "sudo darwin-rebuild switch --flake ~/.config/nix";
      libreoffice = "soffice";
      bundletool = "java -jar /opt/homebrew/opt/bundletool/libexec/bundletool-all.jar";
      setup = "$SETUP_PATH";
    };

    oh-my-zsh = {
      enable = true;
      plugins = [ "git" "zoxide" "direnv" "aws" "react-native" "flutter" ];
      theme = "eastwood";
    };
  };
}
