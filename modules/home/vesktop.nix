_: {
  flake.modules.homeManager.vesktop =
    { config, ... }:
    let
      c = config.colors;
    in
    {
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
        # catppuccin.vesktop puts settings.json in the store, ui toggled plugins must be restated here
        vencord.settings = {
          useQuickCss = true;
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
        # the oled rebuild cannot reach the remote theme @import, quickcss repaints its surface tokens
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
            --background-base-lower: ${c.mantle} !important;
            --background-mod-subtle: ${c.mantle} !important;
            --bg-surface-raised: ${c.mantle} !important;
            --channeltextarea-background: ${c.mantle} !important;
            --custom-channel-members-bg: ${c.mantle} !important;
            --user-profile-overlay-background: ${c.mantle} !important;
            --background-base-lowest: ${c.crust} !important;
            --input-background-default: ${c.crust} !important;
            --scrollbar-auto-track: ${c.crust} !important;
            --scrollbar-auto-scrollbar-color-track: ${c.crust} !important;
          }

          .visual-refresh.theme-dark.theme-dark.hljs,
          .visual-refresh .theme-dark.theme-dark.hljs {
            background: ${c.bg} !important;
          }
        '';
      };
    };
}
