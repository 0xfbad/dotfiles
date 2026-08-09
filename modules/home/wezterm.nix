_: {
  flake.modules.homeManager.wezterm =
    {
      config,
      lib,
      ...
    }:
    let
      c = config.colors;
    in
    {
      programs.wezterm = {
        enable = true;

        settings = {
          color_scheme = "Catppuccin Mocha";
          colors.background = c.bg;
          font = lib.generators.mkLuaInline ''wezterm.font("JetBrainsMono Nerd Font")'';
          font_size = 11;
          scrollback_lines = 10000;
          audible_bell = "Disabled";
          warn_about_missing_glyphs = false;
          enable_tab_bar = false;
          window_close_confirmation = "NeverPrompt";
          term = "wezterm";
          enable_kitty_keyboard = true;
          text_min_contrast_ratio = 4.5;
          disable_default_key_bindings = true;
          # niri is not in tiling_desktop_environments, so wezterm would try to resize on font change
          adjust_window_size_when_changing_font_size = false;
          window_padding = {
            left = 3;
            right = 3;
            top = 0;
            bottom = 0;
          };
          # both fields are mandatory, WindowContentAlignment has no per field default
          window_content_alignment = {
            horizontal = "Left";
            vertical = "Bottom";
          };
        };

        extraConfig = ''
          return {
            keys = {
              {
                key = "c",
                mods = "CTRL|SHIFT",
                action = wezterm.action_callback(function(window, pane)
                  local sel = window:get_selection_text_for_pane(pane)
                  if sel and sel ~= "" then
                    window:perform_action(wezterm.action.CopyTo("Clipboard"), pane)
                  end
                end),
              },
              { key = "v", mods = "CTRL|SHIFT", action = wezterm.action.PasteFrom("Clipboard") },
              { key = "=", mods = "CTRL", action = wezterm.action.IncreaseFontSize },
              { key = "-", mods = "CTRL", action = wezterm.action.DecreaseFontSize },
              { key = "0", mods = "CTRL", action = wezterm.action.ResetFontSize },
              { key = "L", mods = "CTRL|SHIFT", action = wezterm.action.ShowDebugOverlay },
              { key = "P", mods = "CTRL|SHIFT", action = wezterm.action.ActivateCommandPalette },
            },
          }
        '';
      };
    };
}
