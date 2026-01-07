{ primaryUser, ... }:
{
  imports = [
    ./packages.nix
    ./git.nix
    ./shell.nix
    ./gpg.nix
  ];

  home = {
    username = primaryUser;
    stateVersion = "25.11";
  };
}
