_: {
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    initContent = ''
      # Source .profile if it exists (for environment variables set in bash profile)
      [[ -f "$HOME/.profile" ]] && source "$HOME/.profile"

      # Start ssh-agent and add GitHub key if not running/present
      if ! ssh-add -l > /dev/null; then
        ssh-add --apple-use-keychain ~/.ssh/id_ed25519_fn
      fi

      # Load fnm (Fast Node Manager)
      eval "$(fnm env --use-on-cd --shell zsh)"
      export COREPACK_HOME="$HOME/.cache/corepack"
      export PATH="$COREPACK_HOME/bin:$PATH"

      # Source AWS Utils
      [[ -f "$HOME/.aws_utils.zsh" ]] && source "$HOME/.aws_utils.zsh"

      # Source NPM Utils, which set NPM token for FN private registry
      [[ -f "$HOME/.npm_utils.zsh" ]] && source "$HOME/.npm_utils.zsh"

      # Load NVM (Node Version Manager)
      export NVM_DIR="$HOME/.nvm"
      [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
      [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

      # Added by Antigravity
      export PATH="/Users/khandkermahmudur/.antigravity/antigravity/bin:$PATH"

      # Set JAVA_HOME to Zulu 17 if available
      if command -v /usr/libexec/java_home >/dev/null 2>&1; then
        export JAVA_HOME=$(/usr/libexec/java_home -v 17 2>/dev/null || echo "")
        if [ -n "$JAVA_HOME" ]; then
          export PATH="$JAVA_HOME/bin:$PATH"
        fi
      fi

      # Set ANDROID_HOME for Android SDK (from Android Studio)
      export ANDROID_HOME="$HOME/Library/Android/sdk"
      if [ -d "$ANDROID_HOME" ]; then
        export PATH="$ANDROID_HOME/platform-tools:$PATH"
        export PATH="$ANDROID_HOME/tools:$PATH"
        export PATH="$ANDROID_HOME/tools/bin:$PATH"
        
        # Set ANDROID_NDK_HOME to the latest NDK version
        if [ -d "$ANDROID_HOME/ndk" ]; then
          export ANDROID_NDK_HOME="$(ls -d $ANDROID_HOME/ndk/* 2>/dev/null | tail -n 1)"
          export NDK_HOME="$ANDROID_NDK_HOME"
        fi
      fi
    '';

    shellAliases = {
      la = "ls -la";
      ".." = "cd ..";
      "nix-switch" = "sudo darwin-rebuild switch --flake ~/.config/nix";
    };

    oh-my-zsh = {
      enable = true;
      plugins = [ "git" "zoxide" "direnv" ];
      theme = "eastwood";
    };
  };
}
