_: {
  flake.homeModules.zed = _: {
    programs.zed-editor = {
      enable = true;
      extensions = ["catppuccin"];
      mutableUserSettings = false;
      userSettings = {
        # privacy
        telemetry = {
          diagnostics = false;
          metrics = false;
        };
        disable_ai = true;
        auto_update = false;
        features.edit_prediction_provider = "none";
        edit_predictions.provider = "none";
        show_edit_predictions = false;

        # no language servers, this is for quick viewing
        enable_language_server = false;

        # kill all social/collab/ai panels
        show_call_status_icon = false;
        collaboration_panel.button = false;
        chat_panel.button = false;
        notification_panel.button = false;
        agent = {
          enabled = false;
          button = false;
        };

        # catppuccin mocha with oled black overrides
        theme = {
          mode = "dark";
          dark = "Catppuccin Mocha";
          light = "Catppuccin Mocha";
        };
        "experimental.theme_overrides" = {
          background = "#000000";
          "editor.background" = "#000000";
          "panel.background" = "#000000";
          "tab_bar.background" = "#000000";
          "title_bar.background" = "#000000";
          "toolbar.background" = "#000000";
          "status_bar.background" = "#000000";
          "scrollbar.track.background" = "#000000";
        };

        # fonts (match helix/wezterm)
        buffer_font_family = "JetBrainsMono Nerd Font";
        buffer_font_size = 15;
        ui_font_family = "JetBrainsMono Nerd Font";
        ui_font_size = 14;

        # minimal ui
        vim_mode = false;
        toolbar = {
          breadcrumbs = false;
          quick_actions = false;
          selections_menu = false;
        };
        title_bar = {
          show_branch_icon = false;
          show_branch_name = false;
          show_project_items = false;
          show_onboarding_banner = false;
          show_user_picture = false;
          show_user_menu = false;
          show_sign_in = false;
        };
        tab_bar = {
          show = true;
          show_nav_history_buttons = false;
          show_tab_bar_buttons = false;
        };
        scrollbar.show = "never";
        minimap.show = "never";
        gutter = {
          line_numbers = true;
          runnables = false;
          folds = false;
        };
        indent_guides.enabled = false;
        project_panel = {
          button = true;
          starts_open = false;
          git_status = false;
        };
        outline_panel.button = false;
        git_panel.button = false;
        terminal.button = false;
        search.button = false;

        # behavior
        restore_on_startup = "none";
        confirm_quit = false;
        cursor_blink = false;
        current_line_highlight = "gutter";
        show_completions_on_input = false;
        hover_popover_enabled = false;
        format_on_save = "off";
        auto_install_extensions = {};

        window_decorations = "server";
      };
    };
  };
}
