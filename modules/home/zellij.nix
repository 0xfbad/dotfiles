_: {
  flake.modules.homeManager.zellij =
    {
      pkgs,
      lib,
      ...
    }:
    {
      programs.zellij = {
        enable = true;

        # only background 24 24 37 is chrome, the base lines are text drawn on colored ribbons
        themes.catppuccin-oled =
          builtins.replaceStrings
            [ "catppuccin-mocha" "background 24 24 37" ]
            [ "catppuccin-oled" "background 0 0 0" ]
            (
              builtins.readFile (
                builtins.fetchurl {
                  url = "https://raw.githubusercontent.com/zellij-org/zellij/v0.44.3/zellij-utils/assets/themes/catppuccin-mocha.kdl";
                  sha256 = "1pb039n0w4wgdc4xk795b68q3qq410dirn2pjbf6qcn6yfa9j06d";
                }
              )
            );

        settings = {
          theme = "catppuccin-oled";
          default_layout = "compact";
          pane_frames = false;
          show_startup_tips = false;
          show_release_notes = false;
          on_force_close = "quit";
          session_serialization = true;
          serialize_pane_viewport = true;
          scrollback_lines_to_serialize = 1000;
          serialization_interval = 10;
          scroll_mode_sync = false;
          web_server = false;
          web_sharing = "disabled";
          scrollback_editor = lib.getExe pkgs.helix;
        };
      };
    };
}
