_: {
  flake.modules.homeManager.yazi =
    { pkgs, ... }:
    let
      yazi-flavors = pkgs.fetchFromGitHub {
        owner = "yazi-rs";
        repo = "flavors";
        rev = "1183892c904f7f0efdf4473e856ed308b7bea98d";
        hash = "sha256-E1OUF1+mT0V3crVxkewG2Y7hRu8fO+0oRl6NlINmw+o=";
      };
    in
    {
      programs.yazi = {
        enable = true;
        shellWrapperName = "y";
        flavors.catppuccin-mocha = "${yazi-flavors}/catppuccin-mocha.yazi";

        theme.flavor.dark = "catppuccin-mocha";

        plugins = {
          full-border = {
            package = pkgs.yaziPlugins.full-border;
            setup = true;
          };
          git = {
            package = pkgs.yaziPlugins.git;
            setup = true;
          };
          starship = {
            package = pkgs.yaziPlugins.starship;
            setup = true;
          };
          smart-enter = pkgs.yaziPlugins.smart-enter;
        };

        settings.mgr.sort_fallback = "natural";

        settings.plugin.prepend_fetchers = [
          {
            id = "git";
            url = "*";
            run = "git";
            group = "git";
          }
          {
            id = "git";
            url = "*/";
            run = "git";
            group = "git";
          }
        ];

        keymap.mgr.prepend_keymap = [
          {
            on = "l";
            run = "plugin smart-enter";
            desc = "Enter the child directory, or open the file";
          }
        ];
      };
    };
}
