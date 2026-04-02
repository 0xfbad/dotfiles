_: {
  flake.homeModules.wezterm = {config, ...}: let
    c = config.colors;
  in {
    programs.wezterm = {
      enable = true;
      extraConfig = ''
        local wezterm = require("wezterm")
        return {
          color_scheme = "Catppuccin Mocha",
          colors = {
            background = "${c.bg}",
          },
          font = wezterm.font("JetBrainsMono Nerd Font"),
          font_size = 11,
          scrollback_lines = 10000,
          audible_bell = "Disabled",
          warn_about_missing_glyphs = false,
          enable_wayland = true,
          enable_tab_bar = false,
          window_close_confirmation = "NeverPrompt",
          disable_default_key_bindings = true,
          keys = {
            {
              key = "c",
              mods = "CTRL|SHIFT",
              action = wezterm.action_callback(function(window, pane)
                local sel = window:get_selection_text_for_pane(pane)
                if sel and sel ~= "" then
                  window:perform_action(wezterm.action.CopyTo("Clipboard"), pane)
                end
              end)
            },
            { key = "v", mods = "CTRL|SHIFT", action = wezterm.action.PasteFrom("Clipboard") },
          },
          window_padding = {
            left = 3,
            right = 3,
            top = 3,
            bottom = 3,
          },
        }
      '';
    };
  };
}
