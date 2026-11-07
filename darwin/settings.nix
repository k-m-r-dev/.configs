{ self, ... }:
{
  system.stateVersion = 6;
  system.configurationRevision = self.rev or self.dirtyRev or null;

  # Touch ID for sudo is intentionally off: on macOS 26, nix-darwin cannot
  # symlink /etc/pam.d/sudo_local (Operation not permitted even as root).
  security.pam.services.sudo_local.enable = false;

  # Tell zsh to load dotfiles from ~/.config/zsh/ instead of ~/
  # This keeps ~/.zshrc free from Nix symlinks so tools like FVM can write to it
  environment.etc."zshenv".text = ''
    export ZDOTDIR="$HOME/.config/zsh"
  '';
}
