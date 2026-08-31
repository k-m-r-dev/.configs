{ ... }:
{
  homebrew = {
    enable = true;

    onActivation = {
      autoUpdate = false;
      # Temporary workaround: nix-homebrew's patched brew currently errors in
      # formula postinstall for some upgraded packages (e.g. ollama/watchman).
      # Keep upgrades manual until patched brew is updated.
      upgrade = false;
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
      "wizcli"

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
      "bun"
      "ollama"
      "sops"
      "pipx"
      "ios-deploy"
      "watchman"
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
