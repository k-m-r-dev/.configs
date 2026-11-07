# Evaluate feature defaults (requires Nix + nixpkgs on NIX_PATH or flake registry).
#   nix-instantiate --eval --strict -E 'import ./tests/features-eval.nix'
{ lib ? (import <nixpkgs> { }).lib }:
let
  eval = lib.evalModules {
    modules = [ ../modules/features.nix ];
  };
  f = eval.config.my.features;
  checks = [
    (f.awscli.enable == false)
    (f.helix.enable == false)
    (f.zellij.enable == true)
    (f.dockerClient.enable == true)
    (f.onePasswordCli.enable == true)
    (f.rustup.enable == true)
    (f.betterdisplay.enable == true)
    (f.orbstack.enable == true)
    (f.claudeCode.enable == true)
    (f.leanCtx.enable == true)
  ];
in
assert lib.all (x: x) checks;
{
  ok = true;
  awscli = f.awscli.enable;
  zellij = f.zellij.enable;
}
