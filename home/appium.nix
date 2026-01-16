_: {
  # Appium configuration for mobile testing
  home = {
    sessionVariables = {
      # Appium environment variables
      APPIUM_HOME = "$HOME/.appium";
      APPIUM_LOG_LEVEL = "info";
    };
  };

  programs.zsh = {
    initContent = ''
      # Appium configuration
      # Additional environment variables for Appium Doctor diagnostics
      export APPIUM_HOME="$HOME/.appium"
      export APPIUM_LOG_LEVEL="info"

      # Ensure Appium bin directory is in PATH
      if command -v appium >/dev/null 2>&1; then
        export APPIUM_BIN_DIR="$(dirname $(which appium))"
      fi
    '';
  };
}
