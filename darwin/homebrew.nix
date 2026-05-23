{ ... }:
{
  homebrew = {
    enable = true;

    onActivation = {
      autoUpdate = false;
      upgrade = true;
      cleanup = "uninstall"; # was "zap" — downgraded to avoid removing manually-installed casks
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
      # "wezterm" -- incompatible with nix-homebrew patched brew 4.5.6; install manually: brew install --cask wezterm
      # "zed"
      "github-copilot-for-xcode"

      # messaging
      # "discord"
      # "slack"
      # "signal"

      # mobile testing
      "appium-inspector"

      # other
      # Java (Azul Zulu JDK 17) -- incompatible with nix-homebrew patched brew 4.5.6; install manually: brew install --cask zulu@17
      # "zulu@17"
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
      "ollama"
      "sops"
      "wix/brew/applesimutils"
      "lyft/formulae/set-simulator-location"
      "facebook/fb/idb-companion"
      "bundletool"
      "gstreamer"
      "gst-plugins-base"
    ];
    taps = [
      # "nikitabobko/tap"
      "wix/brew"
      "lyft/formulae"
      "facebook/fb"
    ];
  };
}
