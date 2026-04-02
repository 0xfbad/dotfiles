_: {
  flake.homeModules.git = {pkgs, ...}: {
    programs.git = {
      enable = true;
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
      };
    };
  };
}
