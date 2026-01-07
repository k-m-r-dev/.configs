_: {
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    initContent = ''
      eval "$(fnm env --use-on-cd)"
      export COREPACK_HOME="$HOME/.cache/corepack"
      export PATH="$COREPACK_HOME/bin:$PATH"
    '';

    shellAliases = {
      la = "ls -la";
      ".." = "cd ..";
      "nix-switch" = "sudo darwin-rebuild switch --flake ~/.config/nix";
    };

    oh-my-zsh = {
      enable = true;
      plugins = [ "git" "zoxide" "direnv" ];
      theme = "robbyrussell";
    };
  };
}
