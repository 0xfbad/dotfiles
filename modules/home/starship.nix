_: {
  flake.homeModules.starship = {config, ...}: let
    c = config.colors;
    langStyle = c.surface1;
  in {
    programs.starship = {
      enable = true;
      enableZshIntegration = true;
      settings = {
        add_newline = true;
        command_timeout = 200;
        format = "$all";
        right_format = "";

        # second line is just the prompt
        line_break.disabled = false;

        character = {
          success_symbol = "[\\$](bold ${c.accent})";
          error_symbol = "[\\$](bold ${c.red})";
        };

        cmd_duration = {
          min_time = 5000;
          format = "[$duration]($style) ";
          style = c.surface1;
        };

        nix_shell = {
          format = "[($name )](${c.surface1})";
          symbol = "";
          impure_msg = "[impure](bold ${c.red})";
          pure_msg = "";
        };

        # no emoji symbols, just the language name and version
        python = {
          symbol = "";
          format = "[py $version]($style) ";
          style = langStyle;
        };
        rust = {
          symbol = "";
          format = "[rs $version]($style) ";
          style = langStyle;
        };
        golang = {
          symbol = "";
          format = "[go $version]($style) ";
          style = langStyle;
        };
        zig = {
          symbol = "";
          format = "[zig $version]($style) ";
          style = langStyle;
        };
        nodejs = {
          symbol = "";
          format = "[node $version]($style) ";
          style = langStyle;
        };
        typst = {
          symbol = "";
          format = "[typst $version]($style) ";
          style = langStyle;
        };
        docker_context = {
          symbol = "";
          format = "[docker $context]($style) ";
          style = langStyle;
        };

        # hide stuff we don't need on the prompt
        package.disabled = true;
        aws.disabled = true;
        gcloud.disabled = true;
        azure.disabled = true;

        directory = {
          truncation_length = 2;
          truncation_symbol = ".../";
          style = c.accent;
          repo_root_style = "bold ${c.accent}";
          repo_root_format = "[$repo_root]($repo_root_style)[$path]($style)[$read_only]($read_only_style) ";
        };

        git_branch = {
          format = "[$branch]($style) ";
          style = "italic ${c.subtext0}";
        };

        git_status = {
          format = "[$all_status]($style)";
          style = c.red;
          ahead = ">\${count} ";
          diverged = "<>\${ahead_count}>\${behind_count} ";
          behind = "<\${count} ";
          conflicted = " ";
          up_to_date = " ";
          untracked = "? ";
          modified = " ";
          stashed = "";
          staged = "";
          renamed = "";
          deleted = "";
        };
      };
    };
  };
}
