_: {
  flake.homeModules.gitui = {pkgs, ...}: let
    catppuccin-gitui = pkgs.fetchFromGitHub {
      owner = "catppuccin";
      repo = "gitui";
      rev = "df2f59f847e047ff119a105afff49238311b2d36";
      hash = "sha256-DRK/j3899qJW4qP1HKzgEtefz/tTJtwPkKtoIzuoTj0=";
    };
  in {
    programs.gitui = {
      enable = true;
      theme = builtins.readFile "${catppuccin-gitui}/themes/catppuccin-mocha.ron";
    };
  };
}
