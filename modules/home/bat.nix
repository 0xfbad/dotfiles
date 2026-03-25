_: {
  flake.homeModules.bat = {pkgs, ...}: {
    programs.bat = {
      enable = true;
      config.theme = "Catppuccin Mocha";
      extraPackages = with pkgs.bat-extras; [
        batman
        batdiff
        batgrep
      ];
    };
  };
}
