{ pkgs, ... }:
{
  home = {
    packages = with pkgs; [
      # dev tools
      curl
      neovim
      helix
      zellij
      btop
      tree
      ripgrep
      gh
      zoxide
      direnv

      # languages runtimes
      uv
      nodejs_22
      bun

      # fonts
      nerd-fonts.monaspace
    ];
  };
}
