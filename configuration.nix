# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, lib, unstablep, pkgs-18, userSettings, systemSettings, ... }:

 with lib;

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ./systemd-services.nix
      ./github-clone.nix
    ];

  # Bootloader configuration
  boot.loader.grub = {
    enable = true;
    device = "/dev/sda";
    useOSProber = true;
  };

  # Networking settings
  networking = {
    hostName = systemSettings.hostname;
    networkmanager.enable = true;
    useDHCP = false;
    interfaces.eth0.ipv4.addresses = [
      {
        address = "192.168.16.177";
        prefixLength = 24;
      }
    ];
    defaultGateway = "192.168.16.254";
    nameservers = [ "192.168.16.254" "1.1.1.1" ];
    firewall = {
      enable = true;
      allowedTCPPorts = [ 22 3001 ];
      allowedUDPPorts = [ ];
    };
  };

  # Set your time zone.
  time.timeZone = systemSettings.timezone;

  # Locale settings
  i18n = {
    defaultLocale = "en_AU.UTF-8";
    extraLocaleSettings = {
      LC_ADDRESS = "en_AU.UTF-8";
      LC_IDENTIFICATION = "en_AU.UTF-8";
      LC_MEASUREMENT = "en_AU.UTF-8";
      LC_MONETARY = "en_AU.UTF-8";
      LC_NAME = "en_AU.UTF-8";
      LC_NUMERIC = "en_AU.UTF-8";
      LC_PAPER = "en_AU.UTF-8";
      LC_TELEPHONE = "en_AU.UTF-8";
      LC_TIME = "en_AU.UTF-8";
    };
  };

  # X11 and GNOME configuration
  services.xserver = {
    enable = true;
    displayManager.gdm.enable = true;
    desktopManager.gnome.enable = true;
    xkb = {
      layout = "au";
      variant = "";
    };
  };

  # Enable CUPS to print documents.
  services.printing.enable = false;

  # Enable sound with pipewire.
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define user accounts.
  users = {
    mutableUsers = false;
    extraUsers = {
      root = {
        hashedPassword = "*";
      };
      "${userSettings.username}" = {
        isNormalUser = true;
        description = userSettings.name;
        hashedPassword = userSettings.hashedPassword;
        extraGroups = [ "networkmanager" "wheel" "docker"];
        packages = with pkgs; [
          #  thunderbird
        ];
      };
    };
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    wget
    unstablep.brave
    docker_27
    docker-compose
    zip
    unzip
    rar
    unrar
    p7zip
    gnutar
    git
    python3
    iproute2
    ansible
    gh
    openssh
    su
    bat
    zoxide
    fzf
    dust
    sshpass
    yazi
    rsync
  ];

  # NixOS version
  system.stateVersion = "24.05";
  
  # Eperimental features to enable Flakes.
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = true;
    settings.PermitRootLogin = "no";
    settings.AllowUsers = [ "${userSettings.username}" ];
  };
  # Docker service
  virtualisation.docker.enable = true;
  # Qemu guest agent for proxmox
  services.qemuGuest.enable = true;

# This is the activation script that runs at the end of a Nixos rebuild command. It will login
# to the GH cli tool. And use that as an Authentication helper for 'git'.
  system.activationScripts.authenticateGH = lib.mkAfter ''
    ${pkgs.bash}/bin/bash -c '
      set -e
      set -x  # Enable command tracing

      LOGFILE="/var/log/github-authenticateGH.log"

      {
        echo "=== Starting GitHub CLI Authentication ==="
        timestamp=$(date +"%Y-%m-%d %H:%M:%S")
        echo "$timestamp"

        GH="${pkgs.gh}/bin/gh"
        USERNAME="${userSettings.username}"
        PAT_FILE="${userSettings.gitHubPAT-File}"
        SU="/run/wrappers/bin/su"

        echo SU: $SU
        echo GH: $GH
        echo 
        echo "=== Authenticating GitHub CLI using PAT file... ==="
        $SU - $USERNAME  -c "$GH auth login --with-token < $PAT_FILE"

        echo "=== Checking GitHub CLI authentication status... ==="
        $SU - $USERNAME -c "$GH auth status"

        echo "=== Setting Git Authentication ==="
        $SU - $USERNAME -c "$GH auth setup-git"

        
        echo "=== GitHub CLI Authentication Completed ==="
        echo "=== You need to run "GH auth setup-git" ==="
      } | tee -a "$LOGFILE" 2>&1
    '
  '';
# This section is the configuration for the github clone services. You can see exactly
# what is being done in the file 'githu-clone.nix'
  services.githubClone = {
    enable = true;
    repositories = [
      {
        name = "MASTER-NIX";
        url = "github.com/${userSettings.gitHubUser}/MASTER-NIX";
        destination = "home/${userSettings.username}/Flake";
        user = "${userSettings.gitHubUser}";
        schedule = "*-*-* 13:00:00";
        token = "${userSettings.gitHubPAT-File}";
      }
      {
        name = "Ansible";
        url = "github.com/${userSettings.gitHubUser}/ansible";
        destination = "/home/alto/Ansible";
        user = "${userSettings.gitHubUser}";
        schedule = "*-*-* 16:00:00";  # Run at 4pm every day.
        token = "${userSettings.gitHubPAT-File}";
      }
     {
        name = "CMHSPRIOR";
        url = "github.com/${userSettings.gitHubUser}/CMHSPRIOR-NIX";
        destination = "/home/alto/ansible-requirements/CMHSPRIOR-NIX";
        user = "${userSettings.gitHubUser}";
        schedule = "*-*-* 16:00:00";  # Run at 4pm every day.
        token = "${userSettings.gitHubPAT-File}";
      }
    ];
  };  
}