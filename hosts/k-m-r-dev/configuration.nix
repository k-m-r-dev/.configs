{
  pkgs,
  primaryUser,
  hostName,
  ...
}:
{
  networking.hostName = hostName;

  # Feature toggles (see modules/features.nix). Example:
  # my.features.awscli.enable = true;

  # host-specific homebrew casks
  homebrew.casks = [
  ];

  # host-specific home-manager configuration
  home-manager.users.${primaryUser} = {
    home.packages = with pkgs; [
    ];

    programs = {
      zsh = {
        initContent = ''
        '';
      };
    };
  };
}
