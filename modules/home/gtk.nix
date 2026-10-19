{ inputs, ... }:
{
  flake.modules.homeManager.gtk =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      c = config.colors;

      iconThemeName = config.gtk.iconTheme.name;

      schemeName = "CatppuccinMochaMauveOled";

      gtkThemeName = "catppuccin-mocha-mauve-standard";
      catppuccinGtk = pkgs.catppuccin-gtk.override {
        accents = [ "mauve" ];
        variant = "mocha";
      };

      catppuccinKde = pkgs.catppuccin-kde.override {
        flavour = [ "mocha" ];
        accents = [ "mauve" ];
      };

      kdeRgb =
        hex:
        let
          h = lib.removePrefix "#" hex;
          channel = offset: toString (lib.fromHexString (builtins.substring offset 2 h));
        in
        "${channel 0}, ${channel 2}, ${channel 4}";

      # renamed so it does not shadow the scheme catppuccinKde ships
      kdeColors = pkgs.runCommand "${schemeName}.colors" { } ''
        sed -e 's/${kdeRgb c.base}/${kdeRgb c.bg}/g' \
            -e 's/^ColorScheme=.*/ColorScheme=${schemeName}/' \
            -e 's/^Name=.*/Name=Catppuccin Mocha Mauve OLED/' \
          ${catppuccinKde}/share/color-schemes/CatppuccinMochaMauve.colors > $out
      '';

      accents = {
        DecorationFocus = kdeRgb c.accent;
        DecorationHover = kdeRgb c.surface0;
        ForegroundActive = kdeRgb c.peach;
        ForegroundInactive = kdeRgb c.subtext0;
        ForegroundLink = kdeRgb c.accent;
        ForegroundNegative = kdeRgb c.red;
        ForegroundNeutral = kdeRgb c.yellow;
        ForegroundNormal = kdeRgb c.text;
        ForegroundPositive = kdeRgb c.green;
        ForegroundVisited = kdeRgb c.accent;
      };

      colorGroup =
        normal: alternate:
        accents
        // {
          BackgroundNormal = kdeRgb normal;
          BackgroundAlternate = kdeRgb alternate;
        };
    in
    {
      imports = [
        inputs.plasma-manager.homeModules.plasma-manager
      ];

      gtk = {
        enable = true;
        colorScheme = "dark";
        gtk3.bookmarks = map (d: "file://${config.home.homeDirectory}/${d}") [
          "git"
          "Documents"
          "Music"
          "Pictures"
          "Downloads"
          "Videos"
        ];
        gtk4 = {
          # no oled black here, catppuccin-gtk bakes in mocha base
          theme = {
            name = gtkThemeName;
            package = catppuccinGtk;
          };
        };
        font = {
          name = "Noto Sans";
          size = 11;
        };
        theme = {
          name = gtkThemeName;
          package = catppuccinGtk;
        };
      };

      # no qt.style, it sets QT_STYLE_OVERRIDE and darkly is qt6 only
      qt = {
        enable = true;
        platformTheme.name = "kde";
      };

      # qt5 QKdeTheme needs this at 4 or above
      home.sessionVariables.KDE_SESSION_VERSION = "6";
      systemd.user.sessionVariables.KDE_SESSION_VERSION = "6";

      home.packages = [
        # qt6 resolves widgetStyle to this, nothing else installs it
        pkgs.darkly
        pkgs.kdePackages.qqc2-desktop-style
        catppuccinKde
      ];

      xdg.dataFile."color-schemes/${schemeName}.colors".source = kdeColors;

      # written in place by plasma-manager, kde apps edit kdeglobals
      programs.plasma.configFile.kdeglobals = {
        "Colors:Button" = colorGroup c.surface0 c.accent;
        "Colors:Complementary" = colorGroup c.mantle c.crust;
        "Colors:Header" = colorGroup c.mantle c.crust;
        "Colors:Selection" = colorGroup c.accent c.accent // {
          ForegroundNormal = kdeRgb c.crust;
          ForegroundInactive = kdeRgb c.mantle;
        };
        "Colors:Tooltip" = colorGroup c.bg c.crust;
        "Colors:View" = colorGroup c.bg c.mantle;
        "Colors:Window" = colorGroup c.mantle c.crust;

        "ColorEffects:Disabled" = {
          Color = kdeRgb c.bg;
          ColorAmount = "0.3";
          ColorEffect = 2;
          ContrastAmount = "0.1";
          ContrastEffect = 0;
          IntensityAmount = "-1";
          IntensityEffect = 0;
        };

        "ColorEffects:Inactive" = {
          ChangeSelectionColor = true;
          Color = kdeRgb c.bg;
          ColorAmount = "0.5";
          ColorEffect = 3;
          ContrastAmount = "0";
          ContrastEffect = 0;
          Enable = true;
          IntensityAmount = "0";
          IntensityEffect = 0;
        };

        WM = {
          activeBackground = kdeRgb c.bg;
          activeBlend = kdeRgb c.text;
          activeForeground = kdeRgb c.text;
          inactiveBackground = kdeRgb c.crust;
          inactiveBlend = kdeRgb c.subtext0;
          inactiveForeground = kdeRgb c.subtext0;
        };

        General = {
          ColorScheme = schemeName;
          TerminalApplication = "wezterm";
          TerminalService = "org.wezfurlong.wezterm.desktop";
          font = "Noto Sans,11,-1,5,50,0,0,0,0,0";
          fixed = "JetBrainsMono Nerd Font,11,-1,5,50,0,0,0,0,0";
        };

        Icons.Theme = iconThemeName;

        KDE = {
          contrast = 4;
          # qt6 resolves darkly6, qt5 falls back to fusion with the colors above
          widgetStyle = "Darkly";
        };
      };
    };
}
