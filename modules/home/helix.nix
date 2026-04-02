_: {
  flake.homeModules.helix = _: {
    home.stateVersion = "24.11";

    programs.helix = {
      enable = true;
      defaultEditor = true;
      settings = {
        theme = "catppuccin_mocha_transparent";
        editor = {
          scrolloff = 8;
          line-number = "relative";
          soft-wrap.enable = true;
          cursor-shape = {
            insert = "bar";
            normal = "block";
            select = "underline";
          };
          lsp.display-messages = true;
        };
      };
      languages = {
        language-server = {
          ty = {
            command = "ty";
            args = ["server"];
          };
          ruff = {
            command = "ruff";
            args = ["server"];
          };
          rust-analyzer = {
            command = "rust-analyzer";
          };
          gopls = {
            command = "gopls";
          };
          zls = {
            command = "zls";
          };
          typescript-language-server = {
            command = "typescript-language-server";
            args = ["--stdio"];
          };
          dockerfile-language-server = {
            command = "dockerfile-language-server";
            args = ["--stdio"];
          };
          bash-language-server = {
            command = "bash-language-server";
            args = ["start"];
          };
          nil = {
            command = "nil";
          };
          nixd = {
            command = "nixd";
            config.nixd = {
              nixpkgs.expr = ''import (builtins.getFlake "/home/fbad/dotfiles").inputs.nixpkgs { }'';
              formatting.command = ["alejandra"];
              options = {
                nixos.expr = ''(builtins.getFlake "/home/fbad/dotfiles").nixosConfigurations.desktop.options'';
                home-manager.expr = ''(builtins.getFlake "/home/fbad/dotfiles").nixosConfigurations.desktop.options.home-manager.users.type.getSubOptions []'';
              };
            };
          };
          tinymist = {
            command = "tinymist";
          };
          harper-ls = {
            command = "harper-ls";
            args = ["--stdio"];
          };
          hyprls = {
            command = "hyprls";
            args = ["--stdio"];
          };
        };
        language = [
          {
            name = "python";
            language-servers = ["ty" "ruff"];
            auto-format = true;
            formatter = {
              command = "ruff";
              args = ["format" "-"];
            };
          }
          {
            name = "rust";
            language-servers = ["rust-analyzer"];
            auto-format = true;
          }
          {
            name = "go";
            language-servers = ["gopls"];
            auto-format = true;
          }
          {
            name = "zig";
            language-servers = ["zls"];
            auto-format = true;
          }
          {
            name = "typescript";
            language-servers = ["typescript-language-server"];
            auto-format = true;
            formatter = {
              command = "prettierd";
              args = ["--parser" "typescript"];
            };
          }
          {
            name = "javascript";
            language-servers = ["typescript-language-server"];
            auto-format = true;
            formatter = {
              command = "prettierd";
              args = ["--parser" "javascript"];
            };
          }
          {
            name = "tsx";
            language-servers = ["typescript-language-server"];
            auto-format = true;
            formatter = {
              command = "prettierd";
              args = ["--parser" "typescript"];
            };
          }
          {
            name = "jsx";
            language-servers = ["typescript-language-server"];
            auto-format = true;
            formatter = {
              command = "prettierd";
              args = ["--parser" "javascript"];
            };
          }
          {
            name = "dockerfile";
            language-servers = ["dockerfile-language-server"];
          }
          {
            name = "bash";
            language-servers = ["bash-language-server"];
            auto-format = true;
            formatter = {command = "shfmt";};
          }
          {
            name = "nix";
            language-servers = ["nixd" "nil"];
            auto-format = true;
            formatter = {command = "alejandra";};
          }
          {
            name = "typst";
            language-servers = ["tinymist"];
            auto-format = true;
          }
          {
            name = "markdown";
            language-servers = ["harper-ls"];
          }
          {
            name = "git-commit";
            language-servers = ["harper-ls"];
          }
          {
            name = "hyprlang";
            language-servers = ["hyprls"];
          }
        ];
      };
      themes = {
        catppuccin_mocha_transparent = {
          inherits = "catppuccin_mocha";
          "ui.background" = {};
        };
      };
    };
  };
}
