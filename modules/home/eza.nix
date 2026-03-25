_: {
  flake.homeModules.eza = {pkgs, ...}: {
    programs.eza = {
      enable = true;
      enableZshIntegration = true;
      icons = "auto";
    };

    xdg.configFile."eza/theme.yml".source = let
      eza-themes = pkgs.fetchFromGitHub {
        owner = "eza-community";
        repo = "eza-themes";
        rev = "c03051f67e84110fbae91ab7cbc377b3460f035c";
        hash = "sha256-qEC7H9/ghnjkwmMZ788TSgS9ysyIfD+3NHCjxq0Dps0=";
      };
    in "${eza-themes}/themes/catppuccin.yml";
  };
}
