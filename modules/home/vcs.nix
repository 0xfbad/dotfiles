_: {
  flake.modules.homeManager.vcs =
    { config, ... }:
    let
      identity = {
        name = "0xfbad";
        email = "106453412+0xfbad@users.noreply.github.com";
      };

      signingKey = "${config.home.homeDirectory}/.ssh/id_ed25519.pub";
      signingKeyText = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG/CORmjMr16B7/idRN9cBiHisej26eyEnIe0ULE/Tlt";
      allowedSigners = "${config.xdg.configHome}/git/allowed_signers";

      inherit (config) colors;
    in
    {
      programs.gh = {
        enable = true;
        settings.git_protocol = "ssh";
      };

      # registers itself as a gh extension, so this is gh dash
      programs.gh-dash = {
        enable = true;
        settings = {
          prSections = [
            {
              title = "mine";
              filters = "is:open author:@me";
            }
            {
              title = "review";
              filters = "is:open review-requested:@me";
            }
          ];
          issuesSections = [
            {
              title = "mine";
              filters = "is:open author:@me";
            }
          ];
        };
      };

      # ssh signing has no keyring to consult, reads this instead
      xdg.configFile."git/allowed_signers".text = ''
        ${identity.email} namespaces="git" ${signingKeyText}
      '';

      programs.git = {
        enable = true;
        ignores = [ "**/.claude/settings.local.json" ];

        signing = {
          format = "ssh";
          key = signingKey;
          signByDefault = true;
        };

        maintenance = {
          enable = true;
          repositories = [ "${config.home.homeDirectory}/dotfiles" ];
        };

        settings = {
          user = identity;
          pull.rebase = true;
          push.autoSetupRemote = true;
          diff.algorithm = "histogram";
          diff.colorMoved = "zebra";
          diff.colorMovedWS = "allow-indentation-change";
          diff.mnemonicPrefix = true;
          difftool.prompt = false;
          commit.verbose = true;
          branch.sort = "-committerdate";
          column.ui = "auto";
          tag.sort = "-version:refname";
          rerere.enabled = true;
          rerere.autoupdate = true;
          fetch.prune = true;
          fetch.prunetags = true;
          init.defaultBranch = "main";
          core.fsmonitor = true;
          core.untrackedcache = true;
          rebase.autoSquash = true;
          rebase.autoStash = true;
          push.followTags = true;
          push.useForceIfIncludes = true;
          fetch.all = true;
          diff.renames = "copies";
          help.autocorrect = "prompt";
          gpg.ssh.allowedSignersFile = allowedSigners;
        };
      };

      programs.difftastic = {
        enable = true;
        git = {
          enable = true;
          mode = "difftool";
        };
        jujutsu.enable = true;
      };

      # syntax aware merges, owns merge.conflictStyle as diff3 so no zdiff3 in git settings above
      programs.mergiraf = {
        enable = true;
        enableGitIntegration = true;
        enableJujutsuIntegration = true;
      };

      programs.gitui = {
        enable = true;
        theme = builtins.readFile "${config.catppuccin.sources.gitui}/catppuccin-${config.catppuccin.flavor}.ron";
      };

      # renders through jj itself, so the colors below carry into the tui
      programs.jjui.enable = true;

      programs.jujutsu = {
        enable = true;
        settings = {
          user = identity;

          signing = {
            backend = "ssh";
            behavior = "own";
            key = signingKey;
            backends.ssh.allowed-signers = allowedSigners;
          };

          git.sign-on-push = true;

          "--scope" = [
            {
              "--when".repositories = [ "~/dotfiles" ];
              fix.tools.treefmt = {
                command = [
                  "treefmt"
                  "--stdin"
                  "$path"
                ];
                patterns = [ "all()" ];
              };
            }
          ];

          ui = {
            default-command = [ "log" ];
            log-word-wrap = true;
            # git style markers so colocated conflicts stay readable to git tooling
            conflict-marker-style = "git";
          };

          # jj resolves the most specific label, every working_copy default needs its own entry
          colors = {
            change_id = colors.accent;
            "working_copy change_id" = colors.accent;
            commit_id = colors.blue;
            "working_copy commit_id" = colors.blue;
            rest = colors.surface1;
            author = colors.teal;
            "working_copy author" = colors.teal;
            committer = colors.teal;
            "working_copy committer" = colors.teal;
            timestamp = colors.subtext0;
            "working_copy timestamp" = colors.subtext0;
            bookmark = colors.peach;
            "working_copy bookmark" = colors.peach;
            bookmarks = colors.peach;
            "working_copy bookmarks" = colors.peach;
            local_bookmarks = colors.peach;
            "working_copy local_bookmarks" = colors.peach;
            remote_bookmarks = colors.pink;
            "working_copy remote_bookmarks" = colors.pink;
            tag = colors.pink;
            "working_copy tag" = colors.pink;
            tags = colors.pink;
            "working_copy tags" = colors.pink;
            working_copies = colors.green;
            "working_copy working_copies" = colors.green;
            empty = colors.green;
            "working_copy empty" = colors.green;
            conflict = colors.red;
            "working_copy conflict" = colors.red;
            # table form, a bare string would drop the bold half of the default
            error = {
              fg = colors.red;
              bold = true;
            };
            warning = {
              fg = colors.yellow;
              bold = true;
            };
            hint.fg = colors.sky;
          };
        };
      };
    };
}
