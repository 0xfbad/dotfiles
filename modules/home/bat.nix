_: {
  flake.modules.homeManager.bat = { pkgs, ... }: {
    programs.bat = {
      enable = true;
      config = {
        # builtin since bat 0.26.0
        theme = "Catppuccin Mocha";
        italic-text = "always";
        strip-ansi = "auto";
      };
      extraPackages = with pkgs.bat-extras; [
        batman
        (batdiff.override { withDelta = false; })
        batgrep
        batpipe
      ];
    };
  };
}
