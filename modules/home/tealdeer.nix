_: {
  flake.modules.homeManager.tealdeer =
    {
      config,
      lib,
      ...
    }:
    let
      rgb =
        hex:
        let
          h = lib.removePrefix "#" hex;
          byte = i: lib.fromHexString (builtins.substring i 2 h);
        in
        {
          rgb = {
            r = byte 0;
            g = byte 2;
            b = byte 4;
          };
        };

      inherit (config) colors;
    in
    {
      # the enableAutoUpdates timer refreshes the cache
      programs.tealdeer = {
        enable = true;
        settings = {
          display = {
            compact = true;
            show_title = true;
          };

          # the default also falls back to macos and windows pages
          search.platforms = [
            "current"
            "common"
          ];

          style = {
            description.foreground = rgb colors.text;
            command_name = {
              foreground = rgb colors.accent;
              bold = true;
            };
            example_text.foreground = rgb colors.subtext0;
            example_code.foreground = rgb colors.green;
            example_variable = {
              foreground = rgb colors.peach;
              underline = true;
            };
          };
        };
      };
    };
}
