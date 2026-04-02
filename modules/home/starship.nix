_: {
  flake.homeModules.starship = {config, ...}: let
    c = config.colors;
  in {
    programs.starship = {
      enable = true;
      enableZshIntegration = true;
      settings = {
        add_newline = true;
        command_timeout = 200;
        format = "$directory$git_branch$git_status$nix_shell$cmd_duration$character";

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
          impure_msg = "[impure](bold ${c.red})";
          pure_msg = "";
        };

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
