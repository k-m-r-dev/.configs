{
  pkgs,
  primaryUser,
  hostName,
  ...
}:
{
  networking.hostName = hostName;

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
