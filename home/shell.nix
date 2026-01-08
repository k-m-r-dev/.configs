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

      # Load NVM (Node Version Manager)
      export NVM_DIR="$HOME/.nvm"
      [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
      [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

      # Added by Antigravity
      export PATH="/Users/khandkermahmudur/.antigravity/antigravity/bin:$PATH"
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
