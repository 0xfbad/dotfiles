_: {
  flake.homeModules.git = _: {
    programs.git = {
      enable = true;
      settings = {
        pull.rebase = true;
        push.autoSetupRemote = true;
        diff.algorithm = "histogram";
        diff.colorMoved = "plain";
        diff.mnemonicPrefix = true;
        commit.verbose = true;
        branch.sort = "-committerdate";
        column.ui = "auto";
        tag.sort = "-version:refname";
        rerere.enabled = true;
        rerere.autoupdate = true;
      };
    };
  };
}
