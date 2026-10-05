_: {
  flake.modules.homeManager.mcp =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      claudeServers = pkgs.writeText "claude-user-mcp.json" (
        builtins.toJSON {
          excalidraw = lib.hm.mcp.transformMcpServer {
            server = config.programs.mcp.servers.excalidraw;
            extraTransforms = [ lib.hm.mcp.addType ];
            exclude = [ "enabled" ];
          };
        }
      );
      registerClaudeMcp = pkgs.writeShellApplication {
        name = "register-claude-mcp";
        runtimeInputs = [
          pkgs.jq
          pkgs.coreutils
        ];
        text = ''
          target=${lib.escapeShellArg "${config.home.homeDirectory}/.claude.json"} # user scope avoids writing plugins through the private skills symlink
          umask 077
          temporary=$(mktemp "$target.XXXXXX")
          trap 'rm -f "$temporary"' EXIT

          source=/dev/null
          if [ -f "$target" ]; then
            source="$target"
          fi
          jq -s --slurpfile servers ${claudeServers} \
            '(.[0] // {}) | .mcpServers = ((.mcpServers // {}) + $servers[0])' \
            "$source" > "$temporary"
          mv "$temporary" "$target"
        '';
      };
    in
    {
      programs.mcp = {
        enable = true;
        servers.excalidraw.url = "https://mcp.excalidraw.com/mcp";
      };

      programs.codex.enableMcpIntegration = false; # the desktop app also writes this config
      codex.settings.mcp_servers = {
        excalidraw = lib.hm.mcp.transformMcpServer {
          server = config.programs.mcp.servers.excalidraw;
          exclude = [ "type" ];
        };
        canvas = config.canvas.codexServer; # the shared canvas command has no directory restriction
      };

      home.activation.claudeMcp = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        run ${lib.getExe registerClaudeMcp}
      '';
    };
}
