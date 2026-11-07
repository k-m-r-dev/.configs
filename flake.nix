{
  description = "My system configuration";
  inputs = {
    # monorepo w/ recipes ("derivations")
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    nixpkgs-master.url = "github:nixos/nixpkgs/master";

    # manages configs
    home-manager.url = "github:nix-community/home-manager/master";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # system-level software and settings (macOS)
    darwin.url = "github:nix-darwin/nix-darwin/nix-darwin-26.05";
    darwin.inputs.nixpkgs.follows = "nixpkgs";

    # declarative homebrew management
    nix-homebrew.url = "github:zhaofengli/nix-homebrew/09a921d0181146cf6163ec2cc1db7b6fd539a885";
  };

  outputs =
    {
      self,
      darwin,
      nixpkgs,
      home-manager,
      nix-homebrew,
      ...
    }@inputs:
    let
      # Pure multi-host map. Select with:
      #   darwin-rebuild switch --flake ~/.config/nix#$(scutil --get LocalHostName)
      hostNames = [
        "k-m-r-dev"
        "kmrfn"
      ];

      mkDarwin =
        hostName:
        let
          identity = import (./hosts + "/${hostName}/identity.nix");
          primaryUser = identity.primaryUser or (throw "hosts/${hostName}/identity.nix: missing primaryUser");
          sshPrivateKeys = identity.sshPrivateKeys or [ ];
          hostConfig = ./hosts + "/${hostName}/configuration.nix";

          _ =
            assert builtins.isString primaryUser && primaryUser != "";
            assert builtins.isList sshPrivateKeys;
            assert builtins.all (
              k:
              builtins.isString k
              && k != ""
              && builtins.match "[A-Za-z0-9._-]+" k != null
            ) sshPrivateKeys;
            assert builtins.pathExists hostConfig
              || throw "hosts/${hostName}/configuration.nix missing";
            null;
        in
        builtins.seq _ (
          darwin.lib.darwinSystem {
            system = "aarch64-darwin";
            modules = [
              ./darwin
              hostConfig
            ];
            specialArgs = {
              inherit
                inputs
                self
                primaryUser
                hostName
                sshPrivateKeys
                ;
            };
          }
        );
    in
    {
      darwinConfigurations = nixpkgs.lib.genAttrs hostNames mkDarwin;

      # Default package follows this workstation; other hosts: .#darwinConfigurations.<name>.system
      packages.aarch64-darwin = {
        default = self.darwinConfigurations."k-m-r-dev".system;
        darwinSystem = self.darwinConfigurations."k-m-r-dev".system;
      };
    };
}
