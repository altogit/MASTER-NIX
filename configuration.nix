# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, unstablep, pkgs-18, userSettings, systemSettings, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ./systemd-services.nix
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
}