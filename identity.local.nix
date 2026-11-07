# Machine identity (tracked separately from flake.nix). See identity.example.nix.
# Do not put private key contents here — basenames only.
{
  # id -un
  primaryUser = "mahmudur";

  # scutil --get LocalHostName
  hostName = "k-m-r-dev";

  # Basenames only under ~/.ssh. Tried in order; first existing file is ssh-add'd.
  sshPrivateKeys = [
    "id_ed25519_mahmudur85"
  ];
}
