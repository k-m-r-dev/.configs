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
      # Flakes only see git-tracked files. Keep identity in this file (not flake.nix)
      # and track it with git. See identity.example.nix for a fresh-machine template.
      identityPath = ./identity.local.nix;

      identity =
        if builtins.pathExists identityPath then
          import identityPath
        else
          throw ''
            Missing identity.local.nix.

            Copy the example and edit primaryUser, hostName, and sshPrivateKeys:
              cp identity.example.nix identity.local.nix
              git add identity.local.nix

            See README.md (Setup identity). Do not put private key contents here.
          '';

      primaryUser = identity.primaryUser or (throw "identity.local.nix: missing primaryUser");
      hostName = identity.hostName or (throw "identity.local.nix: missing hostName");
      sshPrivateKeys = identity.sshPrivateKeys or (throw "identity.local.nix: missing sshPrivateKeys");

      hostConfig = ./hosts + "/${hostName}/configuration.nix";

      # Validation
      _ =
        assert builtins.isString primaryUser && primaryUser != "";
        assert builtins.isString hostName && hostName != "";
        assert builtins.isList sshPrivateKeys;
        assert builtins.all (
          k:
          builtins.isString k
          && k != ""
          && builtins.match "[A-Za-z0-9._-]+" k != null
        ) sshPrivateKeys;
        assert builtins.pathExists hostConfig
          || throw "identity.local.nix: no hosts/${hostName}/configuration.nix (fix hostName or add that host dir)";
        null;
    in
    # Force validation (unused `_` would be lazy otherwise).
    builtins.seq _ {
      # build darwin flake using:
      # $ darwin-rebuild build --flake .#<name>
      darwinConfigurations."${hostName}" = darwin.lib.darwinSystem {
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
      };

      # Expose the system for `nix build`
      packages.aarch64-darwin = {
        default = self.darwinConfigurations."${hostName}".system;
        darwinSystem = self.darwinConfigurations."${hostName}".system;
      };
    };
}
