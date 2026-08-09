_: {
  flake.modules.homeManager.yazi =
    { pkgs, ... }:
    let
      # newest rev that still parses under yazi 26.5.6, main renames the [which] mask to border
      yazi-flavors = pkgs.fetchFromGitHub {
        owner = "yazi-rs";
        repo = "flavors";
        rev = "c02c804bb7c8873da8182745654fb57dc63b7348";
        hash = "sha256-ZXJx4iwGCAi6qqDiLSuJvX3UL6XzypxSO7ptspDD/Yw=";
      };
    in
    {
      programs.yazi = {
        enable = true;
        shellWrapperName = "y";
        flavors.catppuccin-mocha = "${yazi-flavors}/catppuccin-mocha.yazi";

        # selected from theme.toml not yazi.toml, also points syntect at the flavor tmtheme.xml
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
