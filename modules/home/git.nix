_: {
  flake.homeModules.git = {pkgs, ...}: {
    # gitui's libgit2 needs a real ssh-agent, run ssh-add after first login
    services.ssh-agent.enable = true;
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
  };
}
