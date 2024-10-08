{
  description = "Flake for Master Ansible server";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    oldpkgs.url = "github:NixOS/nixpkgs/nixos-21.11";
    unstablepkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = inputs@{ self, nixpkgs, oldpkgs, unstablepkgs}:
    let
      lib = nixpkgs.lib;
    in {
      nixosConfigurations = {
        MASTER-NIX = nixpkgs.lib.nixosSystem rec {
          system = "x86_64-linux";
          specialArgs = {
            pkgs-18 = import oldpkgs {
              system = system;
              config.allowUnfree = true;
            };
          };
          modules = [
            ./configuration.nix
          ];
        };
      };
    };
}
