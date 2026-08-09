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
          # quit on window close so detached servers do not pile up, ctrl+o d still detaches
          on_force_close = "quit";
          # nothing survives a window close, so serializing sessions is pure waste
          session_serialization = false;
          # off still lets a session opt in at runtime, disabled forbids it
          web_server = false;
          web_sharing = "disabled";
          scrollback_editor = lib.getExe pkgs.helix;
        };
      };
    };
}
