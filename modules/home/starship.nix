_: {
  flake.modules.homeManager.starship =
    {
      config,
      pkgs,
      ...
    }:
    let
      c = config.colors;
      langStyle = c.overlay0;

      claudeOverrides = {
        directory.repo_root_format = "[$repo_root]($repo_root_style)[$path]($style)[$read_only]($read_only_style)";
        git_branch = {
          format = "[/](${c.overlay0})[$branch]($style) ";
          style = "italic ${c.accent}";
        };
        git_commit.format = "[ @$hash]($style) ";
      };
    in
    {
      programs.starship = {
        enable = true;
        enableZshIntegration = true;
        # rewrites the stock emoji symbols of every module $all pulls in
        presets = [ "plain-text-symbols" ];
        extraPackages = [ pkgs.jj-starship ];
        settings = {
          command_timeout = 2000;

          # this only moves the jj id in front of the git segments, $all covers the rest
          format = "$username$hostname$directory\${custom.jj}$all";

          custom.jj = {
            when = "jj-starship detect";
            # no command, starship runs the shell binary itself and feeds $when to its stdin
            shell = [
              "jj-starship"
              "--no-symbol"
              "--no-jj-prefix"
              # the git flags mute it in plain git repos, git_branch already reports there
              "--no-git-prefix"
              "--no-git-name"
              "--no-git-id"
              "--no-git-status"
            ];
            format = "($output )";
          };

          character = {
            success_symbol = "[\\$](bold ${c.accent})";
            error_symbol = "[\\$](bold ${c.red})";
          };

          cmd_duration = {
            min_time = 5000;
            format = "[$duration]($style) ";
            style = c.overlay0;
          };

          nix_shell = {
            heuristic = true;
            format = "[$state( $name )](${c.overlay0})";
            impure_msg = "[impure](bold ${c.red})";
            pure_msg = "[pure](${c.green})";
          };

          direnv = {
            disabled = false;
            format = "[$loaded$allowed]($style)";
            style = langStyle;
            loaded_msg = "";
            unloaded_msg = "direnv ";
            allowed_msg = "";
            not_allowed_msg = "blocked ";
            denied_msg = "denied ";
          };

          python = {
            format = "[py $version(-$virtualenv)]($style) ";
            style = langStyle;
          };
          rust = {
            format = "[rs $version]($style) ";
            style = langStyle;
          };
          golang = {
            format = "[go $version]($style) ";
            style = langStyle;
          };
          zig = {
            format = "[zig $version]($style) ";
            style = langStyle;
          };
          nodejs = {
            format = "[node $version]($style) ";
            style = langStyle;
          };
          typst = {
            format = "[typst $version]($style) ";
            style = langStyle;
          };
          docker_context = {
            format = "[docker $context]($style) ";
            style = langStyle;
          };

          battery.disabled = true;
          package.disabled = true;
          aws.disabled = true;
          gcloud.disabled = true;
          azure.disabled = true;

          directory = {
            # anything above 0 drops repo_root_style once you are that deep in the repo
            truncation_length = 0;
            style = c.accent;
            read_only = " ro";
            read_only_style = c.red;
            repo_root_style = "bold ${c.accent}";
            repo_root_format = "[$repo_root]($repo_root_style)[$path]($style)[$read_only]($read_only_style) ";
          };

          # jj colocation leaves git HEAD detached, so git_commit covers every jj repo
          git_branch = {
            format = "[$branch]($style) ";
            style = "italic ${c.subtext0}";
            only_attached = true;
          };

          git_commit = {
            format = "[$hash]($style) ";
            style = c.green;
          };

          git_state.style = "bold ${c.yellow}";
          jobs.style = c.blue;

          git_status = {
            format = "[$all_status$ahead_behind]($style)";
            style = c.red;
            ahead = ">\${count} ";
            diverged = "<>\${ahead_count}>\${behind_count} ";
            behind = "<\${count} ";
            conflicted = "= ";
            up_to_date = "";
            untracked = "? ";
            modified = "! ";
            stashed = "\\$ ";
            staged = "+ ";
            renamed = "r ";
            deleted = "x ";
          };

          profiles.claude-code = "$claude_model$directory$git_branch$git_commit$git_status$claude_context$claude_cost";

          claude_model = {
            format = "[$model]($style) ";
            style = c.sky;
          };

          claude_context = {
            format = "[$percentage]($style) ";
            display = [
              {
                threshold = 0;
                style = c.green;
              }
              {
                threshold = 60;
                style = c.yellow;
              }
              {
                threshold = 80;
                style = "bold ${c.red}";
              }
            ];
          };

          # claude_cost has no style key in 1.26.0, the color goes inline or it warns
          claude_cost.format = "[\\$$cost](${c.peach}) [+$lines_added](${c.green})[-$lines_removed](${c.red}) [sess $duration, api $api_duration](${c.subtext0}) ";
        };
      };

      xdg.configFile."starship-claude.toml".source =
        pkgs.runCommand "starship-claude.toml" { nativeBuildInputs = [ pkgs.yq ]; }
          ''
            tomlq -s -t 'reduce .[] as $item ({}; . * $item)' \
              ${config.home.file.${config.programs.starship.configPath}.source} \
              ${(pkgs.formats.toml { }).generate "claude-overrides.toml" claudeOverrides} \
              > $out
          '';
    };
}
