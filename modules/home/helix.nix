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
    in
    {
      programs.helix = {
        enable = true;
        # editor only servers, keeps them off the interactive shell PATH
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
            # auto-save writes constantly, keep diffs free of whitespace churn
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
              command = "nixd";
              config.nixd = {
                nixpkgs.expr = ''import (builtins.getFlake "${flakePath}").inputs.nixpkgs { }'';
                formatting.command = [ "nixfmt" ];
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
              # upstream also lists golangci-lint-lsp, that binary is not installed
              name = "go";
              language-servers = [ "gopls" ];
            }
            {
              name = "typescript";
              language-servers = [ "typescript-language-server" ];
              auto-format = true;
              formatter = {
                command = "prettierd";
                args = [
                  "--parser"
                  "typescript"
                ];
              };
            }
            {
              name = "javascript";
              language-servers = [ "typescript-language-server" ];
              auto-format = true;
              formatter = {
                command = "prettierd";
                args = [
                  "--parser"
                  "javascript"
                ];
              };
            }
            {
              name = "tsx";
              language-servers = [ "typescript-language-server" ];
              auto-format = true;
              formatter = {
                command = "prettierd";
                args = [
                  "--parser"
                  "typescript"
                ];
              };
            }
            {
              name = "jsx";
              language-servers = [ "typescript-language-server" ];
              auto-format = true;
              formatter = {
                command = "prettierd";
                args = [
                  "--parser"
                  "javascript"
                ];
              };
            }
            {
              name = "bash";
              language-servers = [ "bash-language-server" ];
              auto-format = true;
              # matches the treefmt-nix shfmt defaults so nix fmt and format on save agree
              formatter = {
                command = "shfmt";
                args = [
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
              };
            }
            {
              name = "typst";
              language-servers = [ "tinymist" ];
              auto-format = true;
            }
            {
              # language-servers replaces rather than appends, so marksman has to be restated
              name = "markdown";
              language-servers = [
                "marksman"
                "harper-ls"
              ];
              auto-format = true;
              formatter = {
                command = "prettierd";
                args = [
                  "--parser"
                  "markdown"
                ];
              };
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
