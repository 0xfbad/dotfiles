_: {
  flake.modules.homeManager.vesktop =
    { config, pkgs, ... }:
    let
      c = config.colors;

      themeSrc = pkgs.fetchurl {
        url = "https://raw.githubusercontent.com/catppuccin/discord/0d8c7aaea33c655bb9e4c93d352a28f3baa69a75/dist/catppuccin-mocha-mauve.theme.css";
        hash = "sha256-kX6O2wxQpZvCF2RjsP4yH+Ojvijd8KJ/uCVu/VObTOg=";
      };

      oledTheme = pkgs.runCommand "catppuccin-mocha-mauve-oled.theme.css" { } ''
        {
          echo "/**"
          echo " * @name Catppuccin Mocha OLED (Mauve)"
          echo " * @description Soothing pastel theme for Discord, black base"
          echo " * @author Catppuccin"
          echo " * @website https://github.com/catppuccin/discord"
          echo "**/"
          sed -e 's/#1e1e2e/${c.bg}/gI' -e 's/#1c1c2b/${c.bg}/gI' ${themeSrc}
        } > $out
      '';
    in
    {
      xdg.configFile."vesktop/themes/catppuccin-mocha-mauve-oled.theme.css".source = oledTheme;

      programs.vesktop = {
        enable = true;
        settings = {
          arRPC = false;
          minimizeToTray = false;
          splashBackground = "rgb(0, 0, 0)";
          splashColor = "rgb(220, 220, 223)";
          spellCheckLanguages = [
            "en-US"
            "en"
          ];
        };
        # settings.json lives in the store, ui toggled plugins must be restated here
        vencord.settings = {
          useQuickCss = true;
          enabledThemes = [ "catppuccin-mocha-mauve-oled.theme.css" ];
          plugins = {
            BadgeAPI.enabled = true;
            CommandsAPI.enabled = true;
            CrashHandler.enabled = true;
            MessageAccessoriesAPI.enabled = true;
            UserSettingsAPI.enabled = true;
            WebKeybinds.enabled = true;
            WebScreenShareFixes.enabled = true;
          };
        };
        vencord.extraQuickCss = ''
          /* doubled class outranks the theme !important rules */
          .visual-refresh.theme-dark.theme-dark,
          .visual-refresh .theme-dark.theme-dark {
            --home-background: ${c.bg} !important;
            --chat-background: ${c.bg} !important;
            --chat-background-default: ${c.bg} !important;
            --background-code: ${c.bg} !important;
            --modal-background: ${c.bg} !important;
            --modal-footer-background: ${c.bg} !important;
            --background-surface-high: ${c.bg} !important;
            --plum-23: ${c.bg} !important;
            --background-base-low: ${c.bg} !important;
            --background-secondary-alt: ${c.bg} !important;
            --background-base-lower: ${c.bg} !important;
            --background-base-lowest: ${c.bg} !important;
            --channeltextarea-background: ${c.bg} !important;
            --custom-channel-members-bg: ${c.bg} !important;
            --background-gradient-lowest: ${c.bg} !important;
            --background-gradient-lower: ${c.bg} !important;
            --background-gradient-low: ${c.bg} !important;
            --background-gradient-high: ${c.bg} !important;
            --background-gradient-higher: ${c.bg} !important;
            --background-gradient-highest: ${c.bg} !important;
            --__header-bar-background: ${c.bg} !important;
            --background-surface-higher: ${c.bg} !important;
            --background-surface-highest: ${c.bg} !important;
            --button-secondary-background: ${c.bg} !important;
            --control-secondary-background-default: ${c.bg} !important;
            --background-mod-subtle: ${c.mantle} !important;
            --bg-surface-raised: ${c.mantle} !important;
            --user-profile-overlay-background: ${c.mantle} !important;
            --input-background-default: ${c.crust} !important;
            --scrollbar-auto-track: ${c.crust} !important;
            --scrollbar-auto-scrollbar-color-track: ${c.crust} !important;
          }

          .visual-refresh.theme-dark.theme-dark.hljs,
          .visual-refresh .theme-dark.theme-dark.hljs {
            background: ${c.bg} !important;
          }

          [class*="channelTextArea"] [aria-label="Send a gift"],
          [class*="channelTextArea"] [aria-label="Open sticker picker"],
          [class*="channelTextArea"] [aria-label="Apps"],
          [class*="backForwardButtons"] {
            display: none !important;
          }
        '';
      };
    };
}
