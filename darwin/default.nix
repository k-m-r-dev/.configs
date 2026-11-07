{
  pkgs,
  inputs,
  self,
  primaryUser,
  config,
  lib,
  ...
}:
{
  imports = [
    ../modules/features.nix
    ./homebrew.nix
    ./settings.nix
    inputs.home-manager.darwinModules.home-manager
    inputs.nix-homebrew.darwinModules.nix-homebrew
  ];

  # nix config
  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      auto-optimise-store = true;
    };
    enable = false; # using determinate installer
  };

  nixpkgs.config.allowUnfree = true;

  # homebrew installation manager
  nix-homebrew = {
    user = primaryUser;
    enable = true;
    autoMigrate = true;
  };

  # home-manager config
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "backup";
    sharedModules = [ ../modules/features.nix ];
    users.${primaryUser} = lib.mkMerge [
      {
        imports = [ ../home ];
      }
      {
        # Mirror darwin feature flags into Home Manager config
        my.features = lib.mapAttrs (_: v: { enable = v.enable; }) config.my.features;
      }
    ];
    extraSpecialArgs = {
      inherit inputs self primaryUser;
      pkgsMaster = import inputs.nixpkgs-master {
        system = pkgs.stdenv.hostPlatform.system;
        config.allowUnfree = true;
      };
    };
  };

  # macOS-specific settings
  system.primaryUser = primaryUser;
  users.users.${primaryUser} = {
    home = "/Users/${primaryUser}";
    shell = pkgs.zsh;
  };
  environment = {
    systemPath = [
      "/opt/homebrew/bin"
      "/Applications/Docker.app/Contents/Resources/bin" # docker-credential-desktop
    ];
    pathsToLink = [ "/Applications" ];
  };
}
