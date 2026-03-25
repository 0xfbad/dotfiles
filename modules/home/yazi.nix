_: {
  flake.homeModules.yazi = {pkgs, ...}: let
    yazi-flavors = pkgs.fetchFromGitHub {
      owner = "yazi-rs";
      repo = "flavors";
      rev = "ffe6e3a16c5c51d7e2dedacf8de662fe2413f73a";
      hash = "sha256-hEnrvfJwCAgM12QwPmjHEwF5xNrwqZH1fTIb/QG0NFI=";
    };
  in {
    programs.yazi = {
      enable = true;
      shellWrapperName = "y";
      enableZshIntegration = true;
      flavors.catppuccin-mocha = "${yazi-flavors}/catppuccin-mocha.yazi";
      settings.flavor.use = "catppuccin-mocha";
    };
  };
}
