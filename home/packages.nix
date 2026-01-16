{ pkgs, pkgsMaster, ... }:
{
  home = {
    packages = with pkgs; [
      # dev tools
      curl
      neovim
      # helix
      # zellij
      btop
      tree
      ripgrep
      gh
      zoxide
      direnv
      kubectl

      # LLM CLIs
      pkgsMaster.opencode
      pkgsMaster.gemini-cli

      # languages runtimes
      uv
      nodejs_22
      bun

      # fonts
      nerd-fonts.monaspace

      # SDK nixpackage managers
      fnm
      watchman

      # npm global CLIs
      nodePackages.eas-cli
      nodePackages.appium-doctor
      nodePackages.appium
      nodePackages.webdriverio

      # Apple development
      cocoapods
    ];
  };
}