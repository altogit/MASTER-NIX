# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, unstablep, pkgs-18, userSettings, systemSettings, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Bootloader.
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda";
  boot.loader.grub.useOSProber = true;

  networking.hostName = systemSettings.hostname; # Define your hostname.

  # Enable networking
  networking.networkmanager.enable = true;

  # Open ports in the firewall.
   networking.firewall.allowedTCPPorts = [ 22 3001 ];
   networking.firewall.allowedUDPPorts = [ ];
  # Or disable the firewall altogether.
   networking.firewall.enable = true;

  # Set your time zone.
  time.timeZone = systemSettings.timezone;

  # Select internationalisation properties.
  i18n.defaultLocale = "en_AU.UTF-8";

  i18n.extraLocaleSettings = {
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

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Enable the GNOME Desktop Environment.
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "au";
    variant = "";
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
        hashedPassword = "$6$gC/dArwhdt2So2tK$y.xbzqelEnKhR1xZbyZCjRd61R.c1lJrRxQRZPVB0dzEuAkOJ0v2ZtnTd1Fvsb0xi6KhdtSFIMuF86T4U.ohf1";
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
  #  vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    wget
    brave
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
  ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.05"; # Did you read the comment?
  
  # Eperimental features to enable Flakes.
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Enabling services.
  
  # Enable the OpenSSH daemon.
  services.openssh.enable = true;
  # Docker service
  virtualisation.docker.enable = true;
  # Qemu guest agent for proxmox
  services.qemuGuest.enable = true;


  # Systemd service to update Flake repository
  systemd.services.updateFlakeRepo = {
    description = "Update Flake Repository";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.git}/bin/git pull";
      User = "${userSettings.username}";
      WorkingDirectory = "/home/alto/Flake";
    };
  };
  # Systemd timer to schedule the service
  systemd.timers.updateFlakeRepo = {
    description = "Timer for updateFlakeRepo.service";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "10min";
      OnUnitActiveSec = "6h 0min";
      Persistent = true;
    };
  };

  # Systemd service to update Ansible repository
  systemd.services.updateAnsibleRepo = {
    description = "Update Ansible Repository";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.git}/bin/git pull";
      User = "${userSettings.username}";
      WorkingDirectory = "/home/alto/Ansible";
    };
  };
  # Systemd timer to schedule the Ansible service
  systemd.timers.updateAnsibleRepo = {
    description = "Timer for updateAnsibleRepo.service";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "10min";
      OnUnitActiveSec = "1h 30min";
      Persistent = true;
    };
  };

  # Systemd service for rebuilding NixOS
  systemd.services.nixosRebuild = {
    description = "Rebuild NixOS Configuration";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.nix}/bin/nixos-rebuild switch --flake ./#MASTER-NIX";
      WorkingDirectory = "/home/alto/Flake";
    };
  };
  # Systemd timer for rebuilding NixOS
  systemd.timers.nixosRebuild = {
    description = "Timer for nixosRebuild.service";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "16:30";
      Persistent = true;
    };
  };
    # Systemd service for running playbook
  systemd.services.ansibleRebootMachines = {
    description = "Reboot all the servers, daily.";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.nix}/bin/ansible-playbook ./main.yml --inventory ../inventory --vault-password-file /home/alto/GH/vault.key &> ./patch.log";
      User = "${userSettings.username}";
      WorkingDirectory = "/home//alto/Ansible/alto/rebootmachines";
    };
  };
  # Systemd timer for rebuilding NixOS
  systemd.timers.ansibleRebootMachines = {
    description = "Timer for ansibleRebootMachines.service";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "04:30";
      Persistent = true;
    };
  };
}