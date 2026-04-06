{ lib, ... }:
{
  # Appium configuration for mobile testing
  home = {
    sessionVariables = {
      # Appium environment variables
      APPIUM_HOME = "$HOME/.appium";
      APPIUM_LOG_LEVEL = "info";
      # Path to bundletool jar installed via Homebrew
      BUNDLETOOL_PATH = "/opt/homebrew/opt/bundletool/libexec/bundletool-all.jar";
    };

    # Post-activation hook to install Appium tools
    activation.appiumSetup = lib.hm.dag.entryAfter [ "installPackages" ] ''
      npm_bin="$(command -v npm || true)"
      if [ -z "$npm_bin" ] && [ -x "$HOME/.nix-profile/bin/npm" ]; then
        npm_bin="$HOME/.nix-profile/bin/npm"
      fi
      if [ -z "$npm_bin" ] && [ -x "/etc/profiles/per-user/$USER/bin/npm" ]; then
        npm_bin="/etc/profiles/per-user/$USER/bin/npm"
      fi

      if [ -n "$npm_bin" ]; then
        PATH="$(dirname "$npm_bin"):$PATH"
      fi

      npm_prefix="$HOME/.npm-global"
      export NPM_CONFIG_PREFIX="$npm_prefix"
      export PATH="$npm_prefix/bin:$PATH"
      mkdir -p "$npm_prefix"

      if [ -z "$npm_bin" ]; then
        echo "npm not found in activation; skipping Appium npm installs"
      else
        # Keep tooling global, but do not pin a single global appium version.
        # Appium versions are selected via npx wrappers in shell init.
        if ! "$npm_bin" list -g @appium/doctor >/dev/null 2>&1; then
          echo "Installing @appium/doctor..."
          "$npm_bin" install -g @appium/doctor
        fi

        if ! "$npm_bin" list -g webdriverio >/dev/null 2>&1; then
          echo "Installing webdriverio..."
          "$npm_bin" install -g webdriverio
        fi

        # Install mjpeg-consumer for MJPEG-over-HTTP features
        if ! "$npm_bin" list -g mjpeg-consumer >/dev/null 2>&1; then
          echo "Installing mjpeg-consumer..."
          "$npm_bin" install -g mjpeg-consumer
        fi
      fi

      # Ensure bundletool jar symlink under ANDROID_HOME
      android_home="''${ANDROID_HOME:-$HOME/Library/Android/sdk}"
      if [ -n "$android_home" ] && [ -f /opt/homebrew/opt/bundletool/libexec/bundletool-all.jar ]; then
        mkdir -p "$android_home"
        ln -sfn /opt/homebrew/opt/bundletool/libexec/bundletool-all.jar "$android_home/bundletool.jar"
      fi

      # Install facebook-idb via pipx if available
      pipx_bin="$(command -v pipx || true)"
      if [ -z "$pipx_bin" ] && [ -x "$HOME/.nix-profile/bin/pipx" ]; then
        pipx_bin="$HOME/.nix-profile/bin/pipx"
      fi
      if [ -z "$pipx_bin" ] && [ -x "/etc/profiles/per-user/$USER/bin/pipx" ]; then
        pipx_bin="/etc/profiles/per-user/$USER/bin/pipx"
      fi
      if [ -n "$pipx_bin" ]; then
        if ! "$pipx_bin" list 2>/dev/null | grep -q "idb"; then
          echo "Installing fb-idb via pipx..."
          "$pipx_bin" install fb-idb || echo "pipx install fb-idb failed (non-fatal)"
        fi
      else
        echo "pipx not found; skipping idb install"
      fi
    '';
  };

  programs.zsh = {
    initContent = ''
      # Appium configuration
      export APPIUM_HOME="$HOME/.appium"
      export APPIUM_LOG_LEVEL="info"

      # Appium multi-version helpers
      # Keep isolated extension/driver trees per major version to avoid peer conflicts.
      appium2_sync_drivers() {
        local home2="$HOME/.appium2"
        local installed
        installed="$(APPIUM_HOME="$home2" npx --yes appium@2.12.1 driver list --installed 2>/dev/null || true)"

        # Enforce exact versions for the Appium 2 workflow.
        if ! echo "$installed" | grep -q "uiautomator2@3.8.2"; then
          APPIUM_HOME="$home2" npx --yes appium@2.12.1 driver uninstall uiautomator2 >/dev/null 2>&1 || true
          APPIUM_HOME="$home2" npx --yes appium@2.12.1 driver install uiautomator2@3.8.2
        fi

        if ! echo "$installed" | grep -q "xcuitest@5.14.0"; then
          APPIUM_HOME="$home2" npx --yes appium@2.12.1 driver uninstall xcuitest >/dev/null 2>&1 || true
          APPIUM_HOME="$home2" npx --yes appium@2.12.1 driver install xcuitest@5.14.0
        fi
      }

      appium3_sync_drivers() {
        local home3="$HOME/.appium3"
        local installed
        installed="$(APPIUM_HOME="$home3" npx --yes appium@3.1.2 driver list --installed 2>/dev/null || true)"

        # Install latest compatible drivers for Appium 3 if missing.
        if ! echo "$installed" | grep -q "uiautomator2@"; then
          APPIUM_HOME="$home3" npx --yes appium@3.1.2 driver install uiautomator2
        fi

        if ! echo "$installed" | grep -q "xcuitest@"; then
          APPIUM_HOME="$home3" npx --yes appium@3.1.2 driver install xcuitest
        fi
      }

      appium3_refresh_drivers() {
        local home3="$HOME/.appium3"
        APPIUM_HOME="$home3" npx --yes appium@3.1.2 driver uninstall uiautomator2 >/dev/null 2>&1 || true
        APPIUM_HOME="$home3" npx --yes appium@3.1.2 driver uninstall xcuitest >/dev/null 2>&1 || true
        APPIUM_HOME="$home3" npx --yes appium@3.1.2 driver install uiautomator2
        APPIUM_HOME="$home3" npx --yes appium@3.1.2 driver install xcuitest
      }

      appium2() {
        appium2_sync_drivers
        APPIUM_HOME="$HOME/.appium2" npx --yes appium@2.12.1 --allow-insecure adb_shell "$@"
      }
      appium3() {
        appium3_sync_drivers
        APPIUM_HOME="$HOME/.appium3" npx --yes appium@3.1.2 "$@"
      }
      appiumv() {
        local version="$1"
        shift
        if [ -z "$version" ]; then
          echo "Usage: appiumv <version> [args...]"
          return 1
        fi
        case "$version" in
          2.*) APPIUM_HOME="$HOME/.appium2" npx --yes "appium@$version" "$@" ;;
          3.*) APPIUM_HOME="$HOME/.appium3" npx --yes "appium@$version" "$@" ;;
          *) APPIUM_HOME="$HOME/.appium" npx --yes "appium@$version" "$@" ;;
        esac
      }
    '';
  };
}

