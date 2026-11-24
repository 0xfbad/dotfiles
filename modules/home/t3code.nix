_: {
  flake.modules.homeManager.t3code =
    {
      config,
      pkgs,
      ...
    }:
    let
      # TEMP sdk sessions read code mode only from the env block of --settings, drop once t3 code turns code mode on itself
      claude = pkgs.writeShellApplication {
        name = "claude";
        runtimeInputs = [ pkgs.jq ];
        text = ''
          code_mode() {
            local set='.env.CLAUDE_CODE_EXPERIMENTAL_CODE_MODE = "1"'

            if [[ $1 == "{"* ]]; then
              jq -c "$set" <<<"$1"
            else
              jq -c "$set" "$1"
            fi
          }

          args=()
          while [ $# -gt 0 ]; do
            case $1 in
              --settings)
                # code mode refuses the t3-code entrypoint, sdk-ts is the sdk default
                export CLAUDE_CODE_ENTRYPOINT=sdk-ts
                args+=(--settings "$(code_mode "$2")")
                shift 2
                ;;
              --settings=*)
                export CLAUDE_CODE_ENTRYPOINT=sdk-ts
                args+=(--settings "$(code_mode "''${1#--settings=}")")
                shift
                ;;
              *)
                args+=("$1")
                shift
                ;;
            esac
          done
          exec ${config.programs.claude-code.finalPackage}/bin/claude "''${args[@]}"
        '';
      };
    in
    {
      home.sessionVariables.T3CODE_TELEMETRY_ENABLED = "false";
      systemd.user.sessionVariables.T3CODE_TELEMETRY_ENABLED =
        config.home.sessionVariables.T3CODE_TELEMETRY_ENABLED;

      programs.t3code = {
        enable = true;
        package = pkgs.t3code.override {
          enableClaude = true;
          claude-code = claude;
          codex = config.programs.codex.package;
          enableJujutsu = true;
        };
      };
    };
}
