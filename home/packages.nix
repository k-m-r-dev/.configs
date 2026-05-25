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
      mysql84

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

      # npm global CLIs
      eas-cli

      # Python tool runners (pipx managed via Homebrew due to nixpkgs build failure)

      # Apple development
      cocoapods
      
      # iOS deployment is installed via Homebrew (nixpkgs build hits impure host deps on macOS)

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

    # npm global packages not available in nixpkgs — managed via activation hook
    activation.npmGlobals = lib.hm.dag.entryAfter [ "installPackages" ] ''
      npm_bin="$(command -v npm || true)"
      if [ -z "$npm_bin" ] && [ -x "$HOME/.nix-profile/bin/npm" ]; then
        npm_bin="$HOME/.nix-profile/bin/npm"
      fi
      if [ -z "$npm_bin" ] && [ -x "/etc/profiles/per-user/$USER/bin/npm" ]; then
        npm_bin="/etc/profiles/per-user/$USER/bin/npm"
      fi

      npm_prefix="$HOME/.npm-global"
      export NPM_CONFIG_PREFIX="$npm_prefix"
      export PATH="$npm_prefix/bin:$PATH"
      mkdir -p "$npm_prefix"

      if [ -z "$npm_bin" ]; then
        echo "npm not found in activation; skipping npm global installs"
      else
        # @opengsd/gsd-pi — keep at npm latest; remove and reinstall if outdated
        gsd_installed="$("$npm_bin" list -g --depth=0 @opengsd/gsd-pi 2>/dev/null | sed -n 's/.*@opengsd\/gsd-pi@\([^ ]*\).*/\1/p' | head -n 1)"
        gsd_latest="$("$npm_bin" view @opengsd/gsd-pi version 2>/dev/null || true)"

        if [ -z "$gsd_latest" ]; then
          echo "Could not fetch @opengsd/gsd-pi latest version; skipping"
        elif [ -z "$gsd_installed" ]; then
          echo "Installing @opengsd/gsd-pi@$gsd_latest..."
          "$npm_bin" install -g @opengsd/gsd-pi@latest
        elif [ "$gsd_installed" != "$gsd_latest" ]; then
          echo "Updating @opengsd/gsd-pi ($gsd_installed -> $gsd_latest)..."
          "$npm_bin" uninstall -g @opengsd/gsd-pi >/dev/null 2>&1 || true
          "$npm_bin" install -g @opengsd/gsd-pi@latest
        fi
      fi
    '';

  };
}