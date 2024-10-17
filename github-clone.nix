{ config, lib, pkgs, userSettings, systemSettings, ... }:

with lib;

let
  # Fetching the data set in 'services.githubClone' in 'configuration.nix'
  cfg = config.services.githubClone;
in
{

  ###### Module Options ######

  options.services.githubClone = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Enable the GitHub repository cloning service.";
    };
    repositories = mkOption {
      type = types.listOf types.attrs;
      default = [];
      description = ''
        A list of repositories to clone or update, each with:
          - `name`: Unique name.
          - `url`: Repository URL.
          - `destination`: Local directory.
          - `user`: User to perform the operations.
          - `schedule`: Timer schedule (e.g., "daily").
          - `token`: (Secret) Personal Access Token (PAT) for authentication.
      '';
    };
  };

  ###### Module Configuration ######

  config = mkIf cfg.enable {
    # Ensure the GitHub CLI and necessary tools are installed
    environment.systemPackages = with pkgs; [
      gh
      git
      bash
      # Add other necessary packages here
    ];
    # Systemd service setup using the provided info.
    systemd.services = listToAttrs (map (repo: {
      name = "githubClone-${repo.name}";
      value = {
        description = "Clone or update Git repository ${repo.url}";
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
        environment = {
          GITHUB_TOKEN_FILE="${repo.token}";
          REPO_URL="${repo.url}";
          GIT="${pkgs.git}/bin/git";
          REPO_USER="${repo.user}";
          REPO_DESTINATION="${repo.destination}";
        };
        serviceConfig = {
          Type = "oneshot";
          User = "${userSettings.username}";
          StandardOutput = "journal";
          StandardError = "journal";
          # This is the script inserted into the systemd service. 
          # When run it will build the authenticated URL and
          # then do a git clone or git pull on the repo.
          ExecStart = ''${pkgs.bash}/bin/sh -c "set -e; \
          GITHUB_TOKEN=$(cat $GITHUB_TOKEN_FILE); \
          echo GHAPI token: \"$GITHUB_TOKEN\"; \
          AUTHENTICATED_URL="https://$REPO_USER:$GITHUB_TOKEN@$REPO_URL"; \
          MASKED_URL=https://$REPO_URL:token@$REPO_URL; \
          echo Masked URL: $MASKED_URL; \
          if [ -d $REPO_DESTINATION/.git ]; then \
            echo Updating repository at $REPO_DESTINATION; \
            $GIT -C $REPO_DESTINATION remote set-url origin $AUTHENTICATED_URL; \
            $GIT -C $REPO_DESTINATION pull --rebase; \
          else \
            echo Cloning repository $MASKED_URL into $REPO_DESTINATION; \
            $GIT clone $AUTHENTICATED_URL $REPO_DESTINATION; \
          fi; \
          $GIT -C $REPO_DESTINATION remote set-url origin https://$REPO_URL"
          ''; 
          # Ensure that the token is not exposed in the environment or logs
          PassEnvironment = [];
        };
      };
    }) cfg.repositories);

    # Systemd timer setup, based on the setting you configured. This timer is what starts the service.
    systemd.timers = listToAttrs (map (repo: {
      name = "githubClone-${repo.name}";
      value = {
        description = "Timer for cloning/updating ${repo.url}";
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = repo.schedule;
          Persistent = true;
        };
      };
    }) cfg.repositories);
  };
}
