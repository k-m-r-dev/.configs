{ self, ... }:
{
  system.stateVersion = 6;
  system.configurationRevision = self.rev or self.dirtyRev or null;

  # touch ID for sudo
  security.pam.services.sudo_local.touchIdAuth = true;

  # Tell zsh to load dotfiles from ~/.config/zsh/ instead of ~/
  # This keeps ~/.zshrc free from Nix symlinks so tools like FVM can write to it
  environment.etc."zshenv".text = ''
    export ZDOTDIR="$HOME/.config/zsh"
  '';
}
