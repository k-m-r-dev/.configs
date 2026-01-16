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

      # Python tool runners
      python311Packages.pipx

      # Apple development
      cocoapods
      
      # iOS deployment and simulator utilities
      ios-deploy

      # iOS location simulation handled via Homebrew tap

      # Screen recording
      ffmpeg
    ];
  };
}