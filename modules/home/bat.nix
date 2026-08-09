_: {
  flake.modules.homeManager.bat = { pkgs, ... }: {
    programs.bat = {
      enable = true;
      config = {
        # catppuccin is builtin since bat 0.26.0, no tmTheme needed
        theme = "Catppuccin Mocha";
        italic-text = "always";
        strip-ansi = "auto";
      };
      extraPackages = with pkgs.bat-extras; [
        batman
        # nothing here ever passes --delta, so keep git-delta out of the closure
        (batdiff.override { withDelta = false; })
        batgrep
        batpipe
      ];
    };
  };
}
