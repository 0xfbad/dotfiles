_: {
  perSystem =
    { pkgs, ... }:
    {
      packages.canvas-lms-mcp = pkgs.callPackage ./_canvas-lms-mcp.nix { };
    };

  flake.modules.homeManager.claude-canvas =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      manifest = "${config.home.homeDirectory}/dotfiles/secretspec.toml";

      canvas-lms-mcp = pkgs.callPackage ./_canvas-lms-mcp.nix { };

      # -S scopes the env to the canvas keys
      canvas-mcp = pkgs.writeShellApplication {
        name = "canvas-mcp";
        runtimeInputs = [ pkgs.secretspec ];
        text = ''
          exec secretspec run -f ${manifest} -P default -S canvas \
            --reason "canvas mcp" -- ${lib.getExe canvas-lms-mcp} --role teacher
        '';
      };

      mcpConfig = pkgs.writeText "mcp.json" (
        builtins.toJSON {
          mcpServers.canvas = {
            type = "stdio";
            command = lib.getExe canvas-mcp;
          };
        }
      );
    in
    {
      options.canvas.dirs = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
      };

      config = {
        home.packages = [ canvas-mcp ];

        # claude walks cwd ancestors for .mcp.json
        home.file = lib.genAttrs (map (d: "${d}/.mcp.json") config.canvas.dirs) (_: {
          source = mcpConfig;
        });
      };
    };
}
