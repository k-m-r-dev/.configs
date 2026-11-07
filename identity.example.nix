# Copy to identity.local.nix and edit for this machine:
#   cp identity.example.nix identity.local.nix
#   git add identity.local.nix
#
# Discover values:
#   id -un
#   scutil --get LocalHostName
#   ls ~/.ssh
#
# Flakes only see git-tracked files. Do not put private key contents here.
{
  # id -un
  primaryUser = "YOUR_MACOS_USERNAME";

  # scutil --get LocalHostName — must match hosts/<hostName>/ and the flake attr (#hostName)
  hostName = "YOUR_LOCAL_HOSTNAME";

  # Basenames only under ~/.ssh. Tried in order; first existing file is ssh-add'd (Apple Keychain).
  # Empty list = no auto ssh-add.
  sshPrivateKeys = [
    # "id_ed25519"
    # "id_ed25519_work"
  ];
}
