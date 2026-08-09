_: {
  flake.modules.homeManager.thunderbird =
    { config, ... }:
    let
      c = config.colors;
    in
    {
      programs.thunderbird = {
        enable = true;

        policies = {
          DisableTelemetry = true;
          DisableAppUpdate = true;
          DisableFeedbackCommands = true;

          # tracking upstream keeps the xpi past strict_max_version bumps without a store pin
          ExtensionSettings."dkim_verifier@pl" = {
            installation_mode = "force_installed";
            install_url = "https://addons.thunderbird.net/thunderbird/downloads/latest/dkim-verifier/latest.xpi";
          };
        };

        settings = {
          "datareporting.policy.dataSubmissionEnabled" = false;
          "datareporting.healthreport.uploadEnabled" = false;
          "toolkit.telemetry.unified" = false;
          "toolkit.telemetry.server" = "data:,";
          "toolkit.telemetry.archive.enabled" = false;
          "toolkit.telemetry.newProfilePing.enabled" = false;
          "toolkit.telemetry.shutdownPingSender.enabled" = false;
          "toolkit.telemetry.updatePing.enabled" = false;
          "toolkit.telemetry.bhrPing.enabled" = false;
          "toolkit.telemetry.firstShutdownPing.enabled" = false;
          "toolkit.coverage.opt-out" = true;
          "breakpad.reportURL" = "";

          # polls a branding endpoint for donation and release messaging
          "mail.inappnotifications.enabled" = false;

          "mailnews.headers.sendUserAgent" = false;
          "mail.suppress_content_language" = true;
          "network.http.referer.XOriginTrimmingPolicy" = 2;
          "network.dns.disablePrefetch" = true;
          "network.prefetch-next" = false;
          "dom.security.https_only_mode" = true;

          "extensions.getAddons.showPane" = false;
          "privacy.donottrackheader.enabled" = true;
          "middlemouse.paste" = false;
        };

        profiles.default = {
          isDefault = true;

          settings = {
            "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
            "mailnews.start_page.enabled" = false;
            "spellchecker.dictionary" = "en-US";
            "layout.spellcheckDefault" = 2;

            # 0 is unthreaded
            "mailnews.default_view_flags" = 0;

            "mailnews.sendInBackground" = true;

            "mailnews.mark_message_read.delay" = true;
            # seconds
            "mailnews.mark_message_read.delay.interval" = 3;

            "mail.server.default.check_all_folders_for_new" = true;

            "mailnews.attachments.display.start_expanded" = true;

            # 3 is sanitized html
            "mailnews.display.html_as" = 3;

            # keep dark message mode, hide the toggle button
            "mail.dark-reader.show-toggle" = false;

            # defaults are 300000 and 30
            "mail.db.idle_limit" = 30000000;
            "mail.db.max_open" = 60;
          };

          userChrome = ''
            :root {
              --lwt-accent-color: ${c.bg} !important;
              --toolbar-background-color: ${c.bg} !important;
              --toolbarbutton-icon-fill: ${c.text} !important;
              --toolbarbutton-icon-fill-opacity: 1 !important;
              --listbox-selected-bg: ${c.accent} !important;
              --listbox-focused-selected-bg: ${c.accent} !important;
              --listbox-selected-color: ${c.bg} !important;
              --listbox-focused-selected-color: ${c.bg} !important;
              --listbox-hover: ${c.mantle} !important;
              --tab-shadow: 0 0 4px #111;
              --toolbar-field-background-color: ${c.mantle} !important;
            }

            #messengerWindow,
            #folderPane,
            #folderTree,
            #threadTree,
            #messagepanebox,
            #messagepane,
            .contentTabInstance,
            #unifiedToolbar,
            #toolbar-menubar,
            #tabs-toolbar,
            #tabmail-tabs {
              background-color: ${c.bg} !important;
            }
            #folderPane {
              border-right: 1px solid ${c.surface0} !important;
            }
            #messagepanebox {
              border-top: 1px solid ${c.surface0} !important;
            }

            /* modern-thunderbird tabs */
            #navigation-toolbox,
            #tabmail-tabs,
            #tabmail-arrowscrollbox {
              min-height: 44px !important;
            }
            .tabmail-tab {
              margin: 4px !important;
            }
            .tab-background {
              padding: 6px;
              border-radius: 4px;
            }
            .tab-line {
              height: 0 !important;
              display: none !important;
            }
            .tabmail-tab::after,
            .tabmail-tab::before {
              border: none !important;
            }
            .tab-background[selected="true"] {
              box-shadow: var(--tab-shadow) !important;
            }
            .tabmail-tab:hover .tab-background:not([selected="true"]) {
              background-color: color-mix(in srgb, currentColor 11%, transparent) !important;
            }
            .tabmail-tab[selected] {
              background-color: ${c.accent} !important;
              color: ${c.bg} !important;
            }
            .tab-close-button {
              padding: 6px !important;
            }
            .tab-close-icon {
              width: 12px !important;
              height: 12px !important;
            }
            .contentTabToolbar {
              height: 40px !important;
            }

            /* modern-thunderbird buttons and search */
            .toolbarbutton-1,
            .themeableSearchBox {
              border: none !important;
              border-radius: 5px !important;
              height: 31px !important;
            }
            .contentTabUrlInput {
              height: 26px !important;
            }

            /* folder pane selection, rows are li wrapping a .container div */
            #folderTree li.selected > .container {
              background-color: ${c.accent} !important;
              color: ${c.bg} !important;
            }
            #folderTree li:not(.selected) > .container:hover {
              background-color: ${c.mantle} !important;
            }

            /* thread cards view, tb 128 and later paint .card-container, not the row */
            #threadTree tr[is="thread-card"].selected .card-container,
            #threadTree tr[is="thread-card"][selected] .card-container {
              background-color: ${c.accent} !important;
              color: ${c.bg} !important;
            }
            #threadTree tr[is="thread-card"].selected .card-container *,
            #threadTree tr[is="thread-card"][selected] .card-container * {
              color: ${c.bg} !important;
            }
            #threadTree tr[is="thread-card"]:hover:not(.selected) .card-container {
              background-color: ${c.mantle} !important;
            }

            /* thread table view fallback */
            #threadTree tr.selected {
              background-color: ${c.accent} !important;
              color: ${c.bg} !important;
            }
            #threadTree tr:hover:not(.selected) {
              background-color: ${c.mantle} !important;
            }

            #folderTree, #threadTree, #messagepanebox {
              color: ${c.text} !important;
            }
          '';

          userContent = ''
            @-moz-document url("about:blank") {
              body { background-color: ${c.bg} !important; }
            }
          '';
        };
      };

      xdg.mimeApps = {
        enable = true;
        defaultApplications = {
          "x-scheme-handler/mailto" = "thunderbird.desktop";
          "message/rfc822" = "thunderbird.desktop";
          "x-scheme-handler/mid" = "thunderbird.desktop";
        };
      };
    };
}
