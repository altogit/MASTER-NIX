{
  description = "Flake for Master Ansible server";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    oldpkgs.url = "github:NixOS/nixpkgs/nixos-21.11";
    unstablepkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = inputs@{ self, nixpkgs, oldpkgs, unstablepkgs}:
    let
      # This is the user settings variables that can be accessed anywhere in the config files
      # To minimise places you need to change things, ie. if you want a different username cjust change it here.
      userSettings = {
        username = "alto";
        name = "Alto";
        hashedPassword = "$6$hdaFwg0d/NhfY1PR$iLeC38mCzOWDF2OU7Hb7Vmeo9lKmMGgxd36w4IhXJYHQ9jyyadF3MqZ9Ck2xdbOsbiqMoz.k1JA2.cobK0ncX0";
        gitHubUser = "altogit";
        gitHubPAT-File = "/home/alto/GH/ghapi";
      };
      # Same as above but just for systemSettings.
      systemSettings = {
        system = "x86_64-linux";
        hostname = "MASTER-NIX";
        timezone = "Australia/Sydney";
      };
    in {
      nixosConfigurations = {
        # MASTER-NIX configuration, the only thing that this Flake will be used for. 
        # You could add more, point them to different config files and use them as 'profiles'.
        MASTER-NIX = nixpkgs.lib.nixosSystem rec {
          specialArgs = {
            # Importing our inputs from above into the MASTER-NIX system.
            pkgs-18 = import oldpkgs {
              system = systemSettings.system;
              config.allowUnfree = true;
            };
            unstablep = import unstablepkgs {
              system = systemSettings.system;
              config.allowUnfree = true;
            };
            # Importing our variables above into the MASTER-NIX system.
            inherit userSettings systemSettings;
          };
          modules = [
            # List of the config files this profile needs.
            ./configuration.nix
          ];
        };
      };
    };
}
