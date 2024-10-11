{ config, lib, pkgs, userSettings, systemSettings, ... }:

with lib;

let
  cfg = config.services.githubClone;
  #GITHUB_TOKEN = "${userSettings.gitHubPAT}";
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

    # Secrets handling: Write the token to a file in /etc with restricted permissions
    # environment.etc = listToAttrs (map (repo: {
    #   name = repo.name;
    #   value = {
    #     source = repo.token;
    #     mode = "0600";
    #     user = repo.user;
    #     group = repo.user;
    #   };
    # }) cfg.repositories);

    # Systemd services
    systemd.services = listToAttrs (map (repo: {
      name = "githubClone-${repo.name}";
      value = {
        description = "Clone or update Git repository ${repo.url}";
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
        serviceConfig = {
          Type = "oneshot";
          User = "${userSettings.username}";
          StandardOutput = "journal";
          StandardError = "journal";
          Environment = [
            #"GITHUB_TOKEN_FILE=/etc/${repo.name}"
            "GITHUB_TOKEN_file=${repo.token}"
            "REPO_URL=${repo.url}"
            "DESTINATION=${repo.destination}"
            "GIT=${pkgs.git}/bin/git"
            "REPO_USER=${repo.user}"
            "REPO_DESTINATION=${repo.destination}"
          ];
          ExecStart = ''
          ${pkgs.bash}/bin/sh -c "set -e; \
          echo $GITHUB_TOKEN_FILE; \
          GITHUB_TOKEN=$(cat $GITHUB_TOKEN_FILE); \
          echo the token: $GITHUB_TOKEN; \
          AUTHENTICATED_URL="https://$REPO_USER:$GITHUB_TOKEN@$REPO_URL"; \
          echo $AUTHENTICATED_URL; \
          MASKED_URL=https://$REPO_URL:<token>@$REPO_URL; \
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

    # Systemd timers
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
