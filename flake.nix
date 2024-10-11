{
  description = "Flake for Master Ansible server";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    oldpkgs.url = "github:NixOS/nixpkgs/nixos-21.11";
    unstablepkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = inputs@{ self, nixpkgs, oldpkgs, unstablepkgs}:
    let
      userSettings = {
        username = "alto";
        name = "Alto";
        hashedPassword = "$6$gC/dArwhdt2So2tK$y.xbzqelEnKhR1xZbyZCjRd61R.c1lJrRxQRZPVB0dzEuAkOJ0v2ZtnTd1Fvsb0xi6KhdtSFIMuF86T4U.ohf1";
        gitHubUser = "altogit";
        gitHubPAT = "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";
      };
      systemSettings = {
        system = "x86_64-linux";
        hostname = "MASTER-NIX";
        timezone = "Australia/Sydney";
      };
    in {
      nixosConfigurations = {
        MASTER-NIX = nixpkgs.lib.nixosSystem rec {
          specialArgs = {
            pkgs-18 = import oldpkgs {
              system = systemSettings.system;
              config.allowUnfree = true;
            };
            unstablep = import unstablepkgs {
              system = systemSettings.system;
              config.allowUnfree = true;
            };
            inherit userSettings systemSettings;
            #inherit (import <nixos/lib>) nixlib;
          };
          modules = [
            ./configuration.nix
          ];
        };
      };
    };
}
