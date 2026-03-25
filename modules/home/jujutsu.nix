_: {
  flake.homeModules.jujutsu = _: {
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
