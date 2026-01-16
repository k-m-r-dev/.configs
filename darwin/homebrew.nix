{ ... }:
{
  homebrew = {
    enable = true;

    onActivation = {
      autoUpdate = false;
      upgrade = true;
      cleanup = "zap";
    };

    # caskArgs.no_quarantine = true;
    # global.brewfile = true;

    # homebrew is best for GUI apps
    # nixpkgs is best for CLI tools
    casks = [
      # OS enhancements
      # "aerospace"
      # "cleanshot"
      # "hiddenbar"
      # "raycast"
      # "betterdisplay"

      # dev
      # "cursor"
      # "ghostty"
      # "visual-studio-code"
      # "wezterm"
      # "zed"

      # messaging
      # "discord"
      # "slack"
      # "signal"

      # mobile testing
      "appium-desktop"
      "appium-inspector"

      # other
      # Java (Azul Zulu JDK 17)
      "zulu@17"
      # "1password"
      # "anki"
      # "brave-browser"
      # "obsidian"
      # "protonvpn"
      # "spotify"
      # "thebrowsercompany-dia"
      # "zen"
    ];
    brews = [
      # "docker"
      # "colima"
    ];
    taps = [
      # "nikitabobko/tap"
    ];
  };
}
