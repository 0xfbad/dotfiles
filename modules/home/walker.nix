_: {
  flake.homeModules.walker = {
    pkgs,
    config,
    ...
  }: let
    c = config.colors;
  in {
    home.packages = [pkgs.walker pkgs.elephant];

    # elephant service (walker's data provider)
    systemd.user.services.elephant = {
      Unit = {
        Description = "Elephant data provider for Walker";
        After = ["graphical-session.target"];
      };
      Service = {
        Type = "simple";
        ExecStart = "${pkgs.elephant}/bin/elephant";
        Restart = "on-failure";
      };
      Install = {
        WantedBy = ["graphical-session.target"];
      };
    };

    xdg.configFile."walker/config.toml".text = ''
      [search]
      placeholder = "search..."
      delay = 0
      force_keyboard_focus = true

      [ui]
      fullscreen = false
      width = 600

      [ui.anchors]
      top = true

      [builtins.applications]
      enabled = true
      prioritize_new = true

      [builtins.clipboard]
      enabled = true
      max_entries = 100

      [builtins.files]
      enabled = true

      [builtins.calc]
      enabled = true

      [builtins.emojis]
      enabled = true

      [builtins.websearch]
      enabled = true
    '';

    xdg.configFile."walker/style.css".text = ''
      * {
        font-family: "JetBrainsMono Nerd Font";
        font-size: 14px;
      }

      #window {
        background: ${c.bgAlpha};
        color: ${c.text};
      }

      #search {
        background: ${c.mantle};
        color: ${c.text};
        border: 2px solid ${c.accent};
        border-radius: 8px;
        padding: 8px 12px;
        margin: 8px;
      }

      #list row:selected {
        background: ${c.accent};
        color: ${c.bg};
        border-radius: 4px;
      }

      #list row {
        padding: 4px 8px;
      }
    '';
  };
}
