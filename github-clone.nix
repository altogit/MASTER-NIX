{ config, lib, pkgs, ... }:

with lib;

let
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

    # Secrets handling
    services.githubClone.secrets = listToAttrs (map (r: {
      name = r.name;
      value = {
        source = r.token;
      };
    }) cfg.repositories);

    # Systemd services
    systemd.services = listToAttrs (map (r: {
      name = "githubClone-${r.name}.service";
      value = {
        description = "Clone or update Git repository ${r.url}";
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
        serviceConfig = {
          Type = "oneshot";
          User = r.user;
          Environment = [
            "GITHUB_TOKEN_FILE=${config.services.githubClone.secrets.${r.name}.path}"
            "REPO_URL=${r.url}"
            "DESTINATION=${r.destination}"
            "GIT=${pkgs.git}/bin/git"
          ];
          ExecStart = ''
            set -e

            # Read the GitHub token
            GITHUB_TOKEN=$(cat "$GITHUB_TOKEN_FILE")

            # Prepare the URL with the token included
            AUTHENTICATED_URL="https://${r.user}:${GITHUB_TOKEN}@${r.url}"

            # Mask the token in logs
            MASKED_URL="https://${r.user}:<token>@${r.url}"

            # Check if the repository exists
            if [ -d "${r.destination}/.git" ]; then
              echo "Updating repository at ${r.destination}"

              # Update the remote URL to include the token
              $GIT -C "${r.destination}" remote set-url origin "${AUTHENTICATED_URL}"

              # Pull with rebase
              $GIT -C "${r.destination}" pull --rebase
            else
              echo "Cloning repository ${MASKED_URL} into ${r.destination}"
              $GIT clone "${AUTHENTICATED_URL}" "${r.destination}"
            fi

            # Reset the remote URL to remove the token after pulling
            $GIT -C "${r.destination}" remote set-url origin "https://${r.url}"
          '';
          # Ensure that the token is not exposed in the environment or logs
          PassEnvironment = [];
        };
      };
    }) cfg.repositories);

    # Systemd timers
    systemd.timers = listToAttrs (map (r: {
      name = "githubClone-${r.name}.timer";
      value = {
        description = "Timer for cloning/updating ${r.url}";
        wantedBy = [ "timers.target" ];
        unitConfig = {
          OnCalendar = r.schedule;
          Persistent = true;
        };
      };
    }) cfg.repositories);
  };
}
