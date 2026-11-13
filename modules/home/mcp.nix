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
    in
    {
      programs.mcp = {
        enable = true;
        servers.excalidraw.url = "https://mcp.excalidraw.com/mcp";
      };

      programs.codex.enableMcpIntegration = true;
      programs.codex.settings.mcp_oauth_credentials_store = "file"; # auto blocks thread/start on a locked keepassxc
      programs.codex.settings.mcp_servers.canvas = config.canvas.codexServer; # programs.mcp.servers.canvas is unscoped

      home.activation.claudeMcp = lib.hm.dag.entryAfter [ "writeBoundary" ] (
        lib.hm.generators.mkImpureConfigMerger {
          inherit pkgs;
          format = "json";
          empty = "{}";
          mode = "600";
          path = "${config.home.homeDirectory}/.claude.json"; # user scope avoids writing plugins through the private skills symlink
          staticSettings = claudeServers;
          jqOperation = "$dynamic | .mcpServers = ((.mcpServers // {}) + $static)";
        }
      );
    };
}
