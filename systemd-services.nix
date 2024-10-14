{ config, pkgs, userSettings, systemSettings, ... }:

{
  systemd.services.nixosRebuild = {
    description = "Rebuild NixOS Configuration";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.nix}/bin/nixos-rebuild switch --flake ./#${systemSettings.hostname}";
      User = userSettings.username;
      WorkingDirectory = "/home/${userSettings.username}/Flake";
    };
  };
  systemd.timers.nixosRebuild = {
    description = "Timer for nixosRebuild.service";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "16:30";
      Persistent = true;
    };
  };

  systemd.services.ansibleRebootMachines = {
    description = "Reboot all the servers, daily.";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.ansible}/bin/ansible-playbook ./main.yml --inventory ../inventory --vault-password-file /home/${userSettings.username}/GH/vault.key";
      User = userSettings.username;
      WorkingDirectory = "/home/${userSettings.username}/Ansible/${userSettings.username}/rebootmachines";
      StandardOutput = "append:/home/${userSettings.username}/Ansible/${userSettings.username}/rebootmachines/patch.log";
      StandardError = "append:/home/${userSettings.username}/Ansible/${userSettings.username}/rebootmachines/patch.log";
      Environment = [
        "HOME=/home/${userSettings.username}"
        "PATH=${pkgs.openssh}/bin:${pkgs.ansible}/bin:${pkgs.coreutils}/bin:${pkgs.python3}/bin:/run/current-system/sw/bin"
      ];
    };
  };
  systemd.timers.ansibleRebootMachines = {
    description = "Timer for ansibleRebootMachines.service";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "04:30";
      Persistent = true;
    };
  };
}
