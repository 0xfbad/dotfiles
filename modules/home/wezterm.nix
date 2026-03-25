_: {
  flake.homeModules.wezterm = _: {
    programs.wezterm = {
      enable = true;
      extraConfig = ''
        local wezterm = require("wezterm")
        return {
          color_scheme = "Catppuccin Mocha",
          colors = {
            background = "#000000",
          },
          font = wezterm.font("JetBrainsMono Nerd Font"),
          font_size = 11,
          enable_wayland = true,
          enable_tab_bar = false,
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
            left = 0,
            right = 0,
            top = 0,
            bottom = 0,
          },
        }
      '';
    };
  };
}
