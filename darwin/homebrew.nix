{ lib, config, ... }:
let
  f = config.my.features;
in
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

    # homebrew is best for GUI apps
    # nixpkgs is best for CLI tools
    casks =
      [
        # always-on / project casks
        # "github-copilot-for-xcode"
        # "appium-inspector" — Homebrew disabled (Gatekeeper) on 2026-09-01; install manually if needed
        # "wizcli"
      ]
      ++ lib.optionals f.betterdisplay.enable [ "betterdisplay" ]
      ++ lib.optionals f.orbstack.enable [ "orbstack" ]
      ++ lib.optionals f.claudeCode.enable [ "claude-code" ];

    brews =
      [
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
      ]
      ++ lib.optionals f.leanCtx.enable [ "yvgude/lean-ctx/lean-ctx" ];

    taps =
      [
        "wix/brew"
        "lyft/formulae"
        "facebook/fb"
      ]
      ++ lib.optionals f.leanCtx.enable [ "yvgude/lean-ctx" ];
  };
}
