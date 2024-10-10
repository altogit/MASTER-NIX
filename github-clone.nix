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
          Environment = [
            #"GITHUB_TOKEN_FILE=/etc/${repo.name}"
            "GITHUB_TOKEN=${userSettings.gitHubPAT}"
            "REPO_URL=${repo.url}"
            "DESTINATION=${repo.destination}"
            "GIT=${pkgs.git}/bin/git"
            "REPO_USER=${repo.user}"
            "REPO_DESTINATION=${repo.destination}"
            "SH=${pkgs.bsh}/bin/sh"
          ];
          ExecStart = ''
            SH -c '
            set -e
            # Prepare the URL with the token included
            AUTHENTICATED_URL="https://$repo.user:$GITHUB_TOKEN@$repo.url"

            # Mask the token in logs
            MASKED_URL="https://$repo.user:<token>@$repo.url"

            # Check if the repository exists
            if [ -d "$repo.destination/.git" ]; then
              echo "Updating repository at $repo.destination"

              # Update the remote URL to include the token
              $GIT -C "$repo.destination" remote set-url origin $AUTHENTICATED_URL

              # Pull with rebase
              $GIT -C "$repo.destination" pull --rebase
            else
              echo "Cloning repository $MASKED_URL into $repo.destination"
              $GIT clone $AUTHENTICATED_URL "$repo.destination"
            fi

            # Reset the remote URL to remove the token after pulling
            $GIT -C "$repo.destination" remote set-url origin "https://$repo.url"
          '
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
