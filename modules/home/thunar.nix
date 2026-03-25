_: {
  flake.homeModules.thunar = _: {
    xfconf.settings = {
      thunar = {
        # details view, hidden files visible
        "last-show-hidden" = true;
        "last-view" = "ThunarDetailsView";
        "last-side-pane" = "ThunarShortcutsPane";
        "last-location-bar" = "ThunarLocationEntry";
        "last-sort-column" = "THUNAR_COLUMN_NAME";
        "last-sort-order" = "GTK_SORT_ASCENDING";

        # clean ui
        "last-menubar-visible" = false;
        "last-statusbar-visible" = true;
        "last-image-preview-visible" = false;
        "misc-small-toolbar-icons" = true;
        "misc-symbolic-icons-in-toolbar" = true;
        "misc-symbolic-icons-in-sidepane" = true;
        "misc-change-window-icon" = true;
        "misc-full-path-in-tab-title" = true;

        # behavior
        "misc-single-click" = false;
        "misc-folders-first" = true;
        "misc-confirm-move-to-trash" = true;
        "misc-show-delete-action" = true;
        "misc-recursive-search" = "THUNAR_RECURSIVE_SEARCH_ALWAYS";
        "misc-remember-geometry" = true;
        "misc-open-new-window-as-tab" = true;
        "misc-middle-click-in-tab" = true;
        "misc-tab-close-middle-click" = true;
        "misc-confirm-close-multiple-tabs" = true;

        # thumbnails
        "misc-thumbnail-mode" = "THUNAR_THUMBNAIL_MODE_ALWAYS";

        # dates
        "misc-date-style" = "THUNAR_DATE_STYLE_YYYYMMDD";
        "misc-file-size-binary" = true;

        # side pane
        "shortcuts-icon-emblems" = true;
        "shortcuts-disk-space-usage-bar" = true;
      };
    };

    xdg.mimeApps.defaultApplications = {
      "inode/directory" = "thunar.desktop";
    };
  };
}
