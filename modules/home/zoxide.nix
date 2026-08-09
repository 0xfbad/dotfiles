_: {
  flake.modules.homeManager.zoxide = _: {
    programs.zoxide = {
      enable = true;
      options = [
        "--cmd"
        "cd"
      ];
    };
  };
}
