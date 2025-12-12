{ pkgs, ... }:

{
  imports = [
    ./terminal.nix
    ./development.nix
    ./desktop.nix
  ];

  home.stateVersion = "24.11";

  # helix with transparent theme and lsp config
  programs.helix = {
    enable = true;
    defaultEditor = true;
    settings = {
      theme = "catppuccin_mocha_transparent";
      editor = {
        line-number = "relative";
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
        pyright = {
          command = "pyright-langserver";
          args = [ "--stdio" ];
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
          args = [ "--stdio" ];
        };
        dockerfile-language-server = {
          command = "dockerfile-language-server";
          args = [ "--stdio" ];
        };
        bash-language-server = {
          command = "bash-language-server";
          args = [ "start" ];
        };
        nil = {
          command = "nil";
        };
        tinymist = {
          command = "tinymist";
        };
      };
      language = [
        {
          name = "python";
          language-servers = [ "pyright" ];
          auto-format = true;
          formatter = { command = "black"; args = [ "-" ]; };
        }
        {
          name = "rust";
          language-servers = [ "rust-analyzer" ];
          auto-format = true;
        }
        {
          name = "go";
          language-servers = [ "gopls" ];
          auto-format = true;
        }
        {
          name = "zig";
          language-servers = [ "zls" ];
          auto-format = true;
        }
        {
          name = "typescript";
          language-servers = [ "typescript-language-server" ];
          auto-format = true;
          formatter = { command = "prettierd"; args = [ "--parser" "typescript" ]; };
        }
        {
          name = "javascript";
          language-servers = [ "typescript-language-server" ];
          auto-format = true;
          formatter = { command = "prettierd"; args = [ "--parser" "javascript" ]; };
        }
        {
          name = "tsx";
          language-servers = [ "typescript-language-server" ];
          auto-format = true;
          formatter = { command = "prettierd"; args = [ "--parser" "typescript" ]; };
        }
        {
          name = "jsx";
          language-servers = [ "typescript-language-server" ];
          auto-format = true;
          formatter = { command = "prettierd"; args = [ "--parser" "javascript" ]; };
        }
        {
          name = "dockerfile";
          language-servers = [ "dockerfile-language-server" ];
        }
        {
          name = "bash";
          language-servers = [ "bash-language-server" ];
          auto-format = true;
          formatter = { command = "shfmt"; };
        }
        {
          name = "nix";
          language-servers = [ "nil" ];
          auto-format = true;
        }
        {
          name = "typst";
          language-servers = [ "tinymist" ];
          auto-format = true;
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
}
