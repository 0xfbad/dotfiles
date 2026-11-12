_: {
  flake.modules.homeManager.syncthing =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      passwordFile = "${config.xdg.stateHome}/syncthing/gui-password";
      manifest = "${config.home.homeDirectory}/dotfiles/secretspec.toml";

      vault = builtins.toJSON {
        id = "vault";
        label = "vault";
        path = "~/Vault";
        versioning = {
          type = "staggered";
          params.maxAge = toString (90 * 24 * 3600);
        };
      };

      # ids stay out of the public repo and the store
      applyDevices = pkgs.writeShellApplication {
        name = "syncthing-devices";
        runtimeInputs = with pkgs; [
          secretspec
          jq
          curl
          libxml2
        ];
        text = ''
          wanted="$(SECRETSPEC_FILE=${manifest} secretspec get -P default SYNCTHING_DEVICES --reason "syncthing devices")"

          config="''${XDG_STATE_HOME:-$HOME/.local/state}/syncthing/config.xml"
          headers="$RUNTIME_DIRECTORY/headers"
          (umask 077; printf 'X-API-Key: %s\n' "$(xmllint --xpath 'string(configuration/gui/apikey)' "$config")" > "$headers")

          api() {
            curl -sSf -H "@$headers" --retry 30 --retry-delay 1 --retry-all-errors "$@"
          }
          base=http://${config.services.syncthing.guiAddress}/rest

          self="$(api "$base/system/status" | jq -r .myID)"

          jq -c 'to_entries[] | {deviceID: .value, name: .key}' <<< "$wanted" |
            while read -r device; do
              api --json "$device" -X POST "$base/config/devices"
            done

          api "$base/config/devices" |
            jq -r --argjson wanted "$wanted" --arg self "$self" \
              '[.[].deviceID] - [$wanted[]] - [$self] | .[]' |
            while read -r id; do
              api -X DELETE "$base/config/devices/$id"
            done

          jq -c --argjson wanted "$wanted" '.devices = [$wanted[] | {deviceID: .}]' <<< ${lib.escapeShellArg vault} |
            api --json @- -X POST "$base/config/folders"

          api "$base/config/folders" | jq -r '.[].id | select(. != "vault")' |
            while read -r id; do
              api -X DELETE "$base/config/folders/$id"
            done
        '';
      };
    in
    {
      home.activation.syncthingGuiPassword =
        lib.hm.dag.entryBetween [ "reloadSystemd" ] [ "writeBoundary" ]
          ''
            if [ ! -s "${passwordFile}" ]; then
              run mkdir -p -m 700 "$(dirname "${passwordFile}")"
              run ${lib.getExe pkgs.bash} -c 'umask 077; head -c 24 /dev/urandom | base64 > "${passwordFile}"'
            fi
          '';

      services.syncthing = {
        enable = true;
        guiCredentials = {
          username = config.home.username;
          inherit passwordFile;
        };
        # syncthing-devices owns these
        overrideDevices = false;
        overrideFolders = false;
        settings.options = {
          urAccepted = -1;
          crashReportingEnabled = false;
        };
      };

      systemd.user.services.syncthing-devices = {
        Unit = {
          Description = "Apply Syncthing devices from secretspec";
          Requires = [ "syncthing.service" ];
          After = [
            "syncthing.service"
            "syncthing-init.service"
          ];
          PartOf = [ "syncthing.service" ];
        };
        Service = {
          Type = "oneshot";
          RemainAfterExit = true;
          RuntimeDirectory = "syncthing-devices";
          ExecStart = lib.getExe applyDevices;
        };
        Install.WantedBy = [ "default.target" ];
      };
    };
}
