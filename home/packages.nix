{ pkgs, pkgsMaster, lib, ... }: # lib used for lib.hiPrio
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
      zoxide
      direnv
      kubectl
      mysql80

      # LLM CLIs
      pkgsMaster.opencode
      pkgsMaster.gemini-cli

      # languages runtimes
      uv
      nodejs_22
      bun
      dart
      php82

      # fonts
      nerd-fonts.monaspace

      # SDK nixpackage managers
      fnm
      fvm
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

      # Google Cloud
      google-cloud-sdk

      k9s

      # JDK versions (zulu17 is default — zulu11 available via use-java 11)
      (lib.hiPrio zulu17)
      zulu11
    ];

  };
}