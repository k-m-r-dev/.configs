{ lib, ... }:
# Declarative feature toggles. Flip booleans instead of commenting packages.
# Override per host in hosts/<name>/configuration.nix, e.g.:
#   my.features.awscli.enable = true;
{
  options.my.features = {
    awscli = {
      enable = lib.mkEnableOption "AWS CLI tools (awscli2 + aws-iam-authenticator)";
    };
    zellij = {
      enable = lib.mkEnableOption "Zellij terminal multiplexer" // { default = true; };
    };
    dockerClient = {
      enable = lib.mkEnableOption "Docker CLI client" // { default = true; };
    };
    onePasswordCli = {
      enable = lib.mkEnableOption "1Password CLI via Nix (_1password-cli)" // {
        default = true;
      };
    };
    rustup = {
      enable = lib.mkEnableOption "rustup toolchain manager" // { default = true; };
    };
    helix = {
      enable = lib.mkEnableOption "Helix editor";
    };
    betterdisplay = {
      enable = lib.mkEnableOption "BetterDisplay Homebrew cask" // { default = true; };
    };
    orbstack = {
      enable = lib.mkEnableOption "OrbStack Homebrew cask" // { default = true; };
    };
    claudeCode = {
      enable = lib.mkEnableOption "Claude Code Homebrew cask (claude-code@latest)" // {
        default = true;
      };
    };
    leanCtx = {
      enable = lib.mkEnableOption "LeanCTX Homebrew tap + brew" // { default = true; };
    };
  };
}
