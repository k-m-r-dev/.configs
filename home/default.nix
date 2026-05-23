{ primaryUser, ... }:
{
  imports = [
    ./packages.nix
    ./git.nix
    ./shell.nix
    ./gpg.nix
    ./appium.nix
    ./ollama.nix
  ];

  home = {
    username = primaryUser;
    stateVersion = "25.11";
  };
}
