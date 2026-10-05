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
          mcpServers.canvas = lib.hm.mcp.transformMcpServer {
            server = config.programs.mcp.servers.canvas;
            extraTransforms = [ lib.hm.mcp.addType ];
            exclude = [ "enabled" ];
          };
        }
      );
      scopedCanvas = pkgs.writeScript "codex-canvas-mcp" ''
        #!${pkgs.python3}/bin/python3
        import json
        import os
        from pathlib import Path
        import sys

        roots = json.loads(${
          builtins.toJSON (builtins.toJSON (map (d: "${config.home.homeDirectory}/${d}") config.canvas.dirs))
        })
        cwd = Path.cwd().resolve()
        if any(cwd.is_relative_to(Path(root).resolve()) for root in roots):  # codex stops inheriting project settings at git roots
            os.execv("${lib.getExe canvas-mcp}", ["${lib.getExe canvas-mcp}"])

        for line in sys.stdin:
            request = json.loads(line)
            if "id" not in request:
                continue

            method = request.get("method")
            response = {"jsonrpc": "2.0", "id": request["id"]}
            if method == "initialize":
                response["result"] = {
                    "protocolVersion": request["params"]["protocolVersion"],
                    "capabilities": {"tools": {}},
                    "serverInfo": {"name": "canvas-outside-course-scope", "version": "1"},
                }
            elif method == "tools/list":
                response["result"] = {"tools": []}
            elif method == "ping":
                response["result"] = {}
            else:
                response["error"] = {
                    "code": -32601,
                    "message": "Canvas is unavailable outside the course directory",
                }

            print(json.dumps(response), flush=True)
      '';
      codexServer = {
        command = toString scopedCanvas;
        startup_timeout_sec = 60;
        tools =
          lib.genAttrs
            [
              "delete_assignment"
              "delete_appointment_group"
              "delete_discussion"
              "delete_file"
              "delete_new_quiz"
              "delete_new_quiz_item"
              "delete_page"
              "delete_peer_review"
            ]
            (_: {
              approval_mode = "prompt";
            });
      };
    in
    {
      options.canvas.dirs = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
      };

      options.canvas.codexServer = lib.mkOption {
        type = lib.types.attrsOf lib.types.anything;
        internal = true;
        readOnly = true;
      };

      config = {
        canvas.codexServer = codexServer;
        canvas.dirs = [ "Projects/CMPM17" ];
        home.packages = [ canvas-mcp ];
        programs.mcp.servers.canvas.command = lib.getExe canvas-mcp;

        home.file = lib.genAttrs (map (d: "${d}/.mcp.json") config.canvas.dirs) (_: {
          source = mcpConfig; # claude walks cwd ancestors for .mcp.json
        });
      };
    };
}
