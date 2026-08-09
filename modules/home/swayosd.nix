_: {
  flake.modules.homeManager.swayosd =
    {
      config,
      pkgs,
      ...
    }:
    let
      serverConfig = (pkgs.formats.toml { }).generate "swayosd-config.toml" {
        server.show_percentage = true;
      };
    in
    {
      # not covered by catppuccin/nix
      services.swayosd = {
        enable = true;
        # read once at startup, going through ExecStart makes sd-switch restart on css changes
        stylePath = pkgs.writeText "swayosd-style.css" ''
          window {
            background: ${config.colors.bg};
            border: 2px solid ${config.colors.accent};
            border-radius: ${toString config.colors.rounding}px;
            padding: 12px;
          }

          label {
            color: ${config.colors.text};
          }

          image {
            color: ${config.colors.text};
          }

          progressbar,
          segmentedprogress {
            border-radius: ${toString config.colors.rounding}px;
          }

          progressbar trough,
          segment {
            background: ${config.colors.surface0};
            border-radius: ${toString config.colors.rounding}px;
            min-height: 8px;
          }

          progressbar progress,
          segment.active {
            background: ${config.colors.accent};
            border-radius: ${toString config.colors.rounding}px;
            min-height: 8px;
          }

          segment {
            margin-left: 8px;
          }

          segment:first-child {
            margin-left: 0;
          }
        '';
      };

      xdg.configFile."swayosd/config.toml".source = serverConfig;

      # config.toml is read once at startup and lives outside the unit
      systemd.user.services.swayosd.Unit.X-Restart-Triggers = [ serverConfig ];
    };
}
