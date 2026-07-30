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
      nodejs_24
      dart
      php82
      rustc
      cargo
      rustfmt
      clippy

      # fonts
      nerd-fonts.monaspace

      # SDK nixpackage managers
      fnm
      fvm

      # npm global CLIs managed via activation.npmGlobals below

      # Python tool runners (pipx managed via Homebrew due to nixpkgs build failure)

      # Apple development
      cocoapods
      
      # iOS deployment is installed via Homebrew (nixpkgs build hits impure host deps on macOS)

      # iOS location simulation handled via Homebrew tap

      # Screen recording
      ffmpeg
      libreoffice-bin

      # Google Cloud
      google-cloud-sdk

      k9s

      # JDK versions (zulu17 is default — zulu11 available via use-java 11)
      (lib.hiPrio zulu17)
      zulu11
    ];

    # Global CLI packages not available in nixpkgs — managed via activation hook
    activation.npmGlobals = lib.hm.dag.entryAfter [ "installPackages" ] ''
      npm_bin="$(command -v npm || true)"
      if [ -z "$npm_bin" ] && [ -x "$HOME/.nix-profile/bin/npm" ]; then
        npm_bin="$HOME/.nix-profile/bin/npm"
      fi
      if [ -z "$npm_bin" ] && [ -x "/etc/profiles/per-user/$USER/bin/npm" ]; then
        npm_bin="/etc/profiles/per-user/$USER/bin/npm"
      fi

      bun_bin=""
      if [ -x "/opt/homebrew/bin/bun" ]; then
        bun_bin="/opt/homebrew/bin/bun"
      elif [ -x "$HOME/.nix-profile/bin/bun" ]; then
        bun_bin="$HOME/.nix-profile/bin/bun"
      elif [ -x "/etc/profiles/per-user/$USER/bin/bun" ]; then
        bun_bin="/etc/profiles/per-user/$USER/bin/bun"
      else
        bun_bin="$(command -v bun || true)"
      fi

      npm_prefix="$HOME/.npm-global"
      export NPM_CONFIG_PREFIX="$npm_prefix"
      export PATH="$npm_prefix/bin:$PATH"
      mkdir -p "$npm_prefix"

      export BUN_INSTALL="$HOME/.bun"
      export PATH="$BUN_INSTALL/bin:$PATH"
      mkdir -p "$BUN_INSTALL/bin"

      if [ -z "$npm_bin" ]; then
        echo "npm not found in activation; skipping npm global installs"
      else
        # Helper: install or update a global npm package to latest
        # Usage: npm_ensure_latest <package>
        npm_ensure_latest() {
          pkg="$1"
          installed="$( "$npm_bin" list -g --depth=0 "$pkg" 2>/dev/null \
            | grep -F "$pkg@" | sed 's/.*@//' | head -n 1 || true )"
          latest="$( "$npm_bin" view "$pkg" version 2>/dev/null || true )"

          if [ -z "$latest" ]; then
            echo "Could not fetch $pkg latest version; skipping"
          elif [ -z "$installed" ]; then
            echo "Installing $pkg@$latest..."
            "$npm_bin" install -g "$pkg@latest"
          elif [ "$installed" != "$latest" ]; then
            echo "Updating $pkg ($installed -> $latest)..."
            "$npm_bin" uninstall -g "$pkg" >/dev/null 2>&1 || true
            "$npm_bin" install -g "$pkg@latest"
          fi
        }

        # @opengsd/gsd-pi — keep at npm latest; remove and reinstall if outdated
        npm_ensure_latest @opengsd/gsd-pi

        # claude-code — keep at npm latest
        npm_ensure_latest @anthropic-ai/claude-code

        # eas-cli — managed here (not nixpkgs) to always track npm latest
        npm_ensure_latest eas-cli
      fi

      if [ -z "$bun_bin" ]; then
        echo "bun not found in activation; skipping bun global installs"
      else
        echo "Ensuring @oh-my-pi/pi-coding-agent is installed via bun..."
        "$bun_bin" install -g @oh-my-pi/pi-coding-agent@latest
      fi
    '';

  };
}