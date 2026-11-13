_: {
  flake.modules.homeManager.helix =
    {
      config,
      osConfig,
      pkgs,
      ...
    }:
    let
      flakePath = "${config.home.homeDirectory}/dotfiles";
      host = osConfig.networking.hostName;

      # prettierd takes a file name and infers the parser from its extension
      prettierd = extension: {
        command = "prettierd";
        args = [ extension ];
      };
    in
    {
      programs.helix = {
        enable = true;
        extraPackages = with pkgs; [
          bash-language-server
          dockerfile-language-server
          gopls
          harper
          marksman
          nixd
          rust-analyzer
          tinymist
          typescript-language-server
          zls
        ];
        ignores = [
          "result"
          "result-*"
          ".direnv/"
          "flake.lock"
        ];
        settings = {
          theme = "catppuccin_mocha_transparent";
          editor = {
            auto-pairs = false;
            default-yank-register = "+";
            scrolloff = 8;
            line-number = "relative";
            soft-wrap.enable = true;
            auto-save.focus-lost = true;
            indent-guides.render = true;
            bufferline = "multiple";
            color-modes = true;
            idle-timeout = 50;
            completion-timeout = 5;
            trim-trailing-whitespace = true;
            trim-final-newlines = true;
            end-of-line-diagnostics = "hint";
            inline-diagnostics = {
              cursor-line = "warning";
              other-lines = "error";
            };
            cursor-shape = {
              insert = "bar";
              normal = "block";
              select = "underline";
            };
            lsp = {
              display-progress-messages = true;
              display-inlay-hints = true;
              inlay-hints-length-limit = 25;
            };
          };
        };
        languages = {
          language-server = {
            nixd = {
              config.nixd = {
                nixpkgs.expr = ''import (builtins.getFlake "${flakePath}").inputs.nixpkgs { }'';
                options = {
                  nixos.expr = ''(builtins.getFlake "${flakePath}").nixosConfigurations.${host}.options'';
                  home-manager.expr = ''(builtins.getFlake "${flakePath}").nixosConfigurations.${host}.options.home-manager.users.type.getSubOptions []'';
                  flake-parts.expr = ''(builtins.getFlake "${flakePath}").debug.options'';
                };
              };
            };
          };
          language = [
            {
              name = "python";
              language-servers = [
                "ty"
                "ruff"
              ];
              auto-format = true;
              formatter = {
                command = "ruff";
                args = [
                  "format"
                  "-"
                ];
              };
            }
            {
              name = "go";
              language-servers = [ "gopls" ]; # drops golangci-lint-lsp from the upstream default
            }
            {
              name = "typescript";
              auto-format = true;
              formatter = prettierd ".ts";
            }
            {
              name = "javascript";
              auto-format = true;
              formatter = prettierd ".js";
            }
            {
              name = "tsx";
              auto-format = true;
              formatter = prettierd ".tsx";
            }
            {
              name = "jsx";
              auto-format = true;
              formatter = prettierd ".jsx";
            }
            {
              name = "bash";
              auto-format = true;
              formatter = {
                command = "shfmt";
                # matches the treefmt shfmt args
                args = [
                  "-ci"
                  "-i"
                  "2"
                  "-s"
                ];
              };
            }
            {
              name = "nix";
              language-servers = [ "nixd" ];
              auto-format = true;
              formatter = {
                command = "nixfmt";
                args = [ "-" ];
              };
            }
            {
              name = "typst";
              auto-format = true;
            }
            {
              name = "markdown";
              # language-servers replaces the default, marksman restated
              language-servers = [
                "marksman"
                "harper-ls"
              ];
              auto-format = true;
              formatter = prettierd ".md";
            }
            {
              name = "git-commit";
              language-servers = [ "harper-ls" ];
            }
          ];
        };
        themes = {
          catppuccin_mocha_transparent = {
            inherits = "catppuccin_mocha";
            "ui.background" = { };
            "ui.menu" = {
              bg = config.colors.bg;
            };
            "ui.popup" = {
              bg = config.colors.bg;
            };
            "ui.statusline" = {
              bg = config.colors.mantle;
            };
          };
        };
      };
    };
}
