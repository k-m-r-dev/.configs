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
      export APPIUM_HOME="$HOME/.appium"
      export APPIUM_LOG_LEVEL="info"
    '';
  };

  # Post-activation hook to install Appium tools
  home.activation.appiumSetup = {
    before = [ "writeBoundary" ];
    data = ''
      # Install Appium tools globally if not already installed
      if ! command -v appium &> /dev/null; then
        echo "Installing Appium..."
        npm install -g appium appium-doctor webdriverio
      fi
    '';
  };
}

