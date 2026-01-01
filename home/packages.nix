{ pkgs, ... }:
{
  home = {
    packages = with pkgs; [
      # dev tools
      curl
      neovim
      zellij
      btop
      tree
      ripgrep
      gh
      zoxide
      gnupg
      pinentry_mac

      # fonts
      nerd-fonts.monaspace
    ];
  };
}
