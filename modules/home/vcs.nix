_: {
  flake.homeModules.vcs = {pkgs, ...}: let
    catppuccin-gitui = pkgs.fetchFromGitHub {
      owner = "catppuccin";
      repo = "gitui";
      rev = "df2f59f847e047ff119a105afff49238311b2d36";
      hash = "sha256-DRK/j3899qJW4qP1HKzgEtefz/tTJtwPkKtoIzuoTj0=";
    };
  in {
    home.packages = with pkgs; [
      gh # GitHub CLI, manage PRs/issues/repos from terminal
      difftastic # modern git diff, parses ASTs via tree-sitter, shows semantic changes
    ];

    programs.git = {
      enable = true;
      signing.format = null;
      settings = {
        pull.rebase = true;
        push.autoSetupRemote = true;
        diff.algorithm = "histogram";
        diff.colorMoved = "plain";
        diff.mnemonicPrefix = true;
        diff.tool = "difftastic";
        difftool.prompt = false;
        "difftool \"difftastic\"".cmd = "${pkgs.difftastic}/bin/difft \"$LOCAL\" \"$REMOTE\"";
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
        merge.conflictstyle = "zdiff3";
        push.followTags = true;
        push.useForceIfIncludes = true;
        fetch.all = true;
        diff.renames = "copies";
        help.autocorrect = "prompt";
      };
    };

    programs.gitui = {
      enable = true;
      theme = builtins.readFile "${catppuccin-gitui}/themes/catppuccin-mocha.ron";
    };

    programs.jujutsu = {
      enable = true;
      settings = {
        ui = {
          default-command = ["log"];
          diff-editor = ":builtin";
          pager = "less -FRX";
          graph.style = "curved";
          log-word-wrap = true;
        };
        git.colocate = true;
      };
    };
  };
}
