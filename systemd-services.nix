{ config, pkgs, userSettings, systemSettings, ... }:

{
  # Service that runs the nix rebuild command daily, to make sure the system is current with the flake files.
  systemd.services.nixosRebuild = {
    description = "Rebuild NixOS Configuration";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "sudo ${pkgs.nix}/bin/nixos-rebuild switch --flake ./#${systemSettings.hostname}";
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
  # Service that runs the Machine reboot playbook.
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
  # Service that Updates servers.
  systemd.services.ansibleUpdateMachines = {
    description = "Update all the servers, weekly.";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.ansible}/bin/ansible-playbook ./main.yml --inventory ../inventory --vault-password-file /home/${userSettings.username}/GH/vault.key";
      User = userSettings.username;
      WorkingDirectory = "/home/${userSettings.username}/Ansible/${userSettings.username}/updatesrv";
      StandardOutput = "append:/home/${userSettings.username}/Ansible/${userSettings.username}/updatesrv/patch.log";
      StandardError = "append:/home/${userSettings.username}/Ansible/${userSettings.username}/updatesrv/patch.log";
      Environment = [
        "HOME=/home/${userSettings.username}"
        "PATH=${pkgs.openssh}/bin:${pkgs.ansible}/bin:${pkgs.coreutils}/bin:${pkgs.python3}/bin:/run/current-system/sw/bin"
      ];
    };
  };
  systemd.timers.ansibleUpdateMachines = {
    description = "Timer for ansibleUpdateMachines.service";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "Sun *-*-* 20:30";
      Persistent = true;
    };
  };
  # Service that Backup servers.
  systemd.services.ansibleBackupMachines = {
    description = "Backup all the servers, 1st of the month.";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.ansible}/bin/ansible-playbook ./main.yml --inventory ../inventory --vault-password-file /home/${userSettings.username}/GH/vault.key";
      User = userSettings.username;
      WorkingDirectory = "/home/${userSettings.username}/Ansible/${userSettings.username}/backup1";
      StandardOutput = "append:/home/${userSettings.username}/Ansible/${userSettings.username}/backup1/patch.log";
      StandardError = "append:/home/${userSettings.username}/Ansible/${userSettings.username}/backup1/patch.log";
      Environment = [
        "HOME=/home/${userSettings.username}"
        "PATH=${pkgs.openssh}/bin:${pkgs.ansible}/bin:${pkgs.coreutils}/bin:${pkgs.python3}/bin:/run/current-system/sw/bin"
      ];
    };
  };
  systemd.timers.ansibleBackupMachines = {
    description = "Timer for ansibleBackupMachines.service";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "*-*-1 00:30";
      Persistent = true;
    };
  };
  # Service that Backup servers.
  systemd.services.ansibleBackup2Machines = {
    description = "Backup all the servers, 15th of the month.";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.ansible}/bin/ansible-playbook ./main.yml --inventory ../inventory --vault-password-file /home/${userSettings.username}/GH/vault.key";
      User = userSettings.username;
      WorkingDirectory = "/home/${userSettings.username}/Ansible/${userSettings.username}/backup2";
      StandardOutput = "append:/home/${userSettings.username}/Ansible/${userSettings.username}/backup2/patch.log";
      StandardError = "append:/home/${userSettings.username}/Ansible/${userSettings.username}/backup2/patch.log";
      Environment = [
        "HOME=/home/${userSettings.username}"
        "PATH=${pkgs.openssh}/bin:${pkgs.ansible}/bin:${pkgs.coreutils}/bin:${pkgs.python3}/bin:/run/current-system/sw/bin"
      ];
    };
  };
  systemd.timers.ansibleBackup2Machines = {
    description = "Timer for ansibleBackup2Machines.service";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "15-*-* 00:30";
      Persistent = true;
    };
  };
  # Service gets the Tally app report.
  systemd.services.ansibleTallyApp = {
    description = "Generate the TallyApp report daily.";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.ansible}/bin/ansible-playbook ./main.yml --inventory ../inventory --vault-password-file /home/${userSettings.username}/GH/vault.key";
      User = userSettings.username;
      WorkingDirectory = "/home/${userSettings.username}/Ansible/${userSettings.username}/tally-app-reports";
      StandardOutput = "append:/home/${userSettings.username}/Ansible/${userSettings.username}/tally-app-reports/patch.log";
      StandardError = "append:/home/${userSettings.username}/Ansible/${userSettings.username}/tally-app-reports/patch.log";
      Environment = [
        "HOME=/home/${userSettings.username}"
        "PATH=${pkgs.openssh}/bin:${pkgs.ansible}/bin:${pkgs.coreutils}/bin:${pkgs.python3}/bin:/run/current-system/sw/bin"
      ];
    };
  };
  systemd.timers.ansibleTallyApp = {
    description = "Timer for ansibleTallyApp.service";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "*-*-* 07:00";
      Persistent = true;
    };
  };
  # Service that deduplicates DCMLTSTORE AND DCMMST Databases.
  systemd.services.ansibleDeduplicate = {
    description = "Deduplicate patients on DCMLTSTORE and DCMMST.";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.ansible}/bin/ansible-playbook ./main.yml --inventory ../inventory --vault-password-file /home/${userSettings.username}/GH/vault.key";
      User = userSettings.username;
      WorkingDirectory = "/home/${userSettings.username}/Ansible/${userSettings.username}/python";
      StandardOutput = "append:/home/${userSettings.username}/Ansible/${userSettings.username}/python/patch.log";
      StandardError = "append:/home/${userSettings.username}/Ansible/${userSettings.username}/python/patch.log";
      Environment = [
        "HOME=/home/${userSettings.username}"
        "PATH=${pkgs.openssh}/bin:${pkgs.ansible}/bin:${pkgs.coreutils}/bin:${pkgs.python3}/bin:/run/current-system/sw/bin"
      ];
    };
  };
  systemd.timers.ansibleDeduplicate = {
    description = "Timer for ansibleDeduplicate.service";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "*-*-* 23:00";
      Persistent = true;
    };
  };
}
