_: {
  flake.homeModules.thunderbird = {
    config,
    pkgs,
    ...
  }: let
    c = config.colors;

    buildThunderbirdAddon = {
      pname,
      version,
      addonId,
      url,
      sha256,
    }:
      pkgs.stdenv.mkDerivation {
        name = "${pname}-${version}";
        src = pkgs.fetchurl {inherit url sha256;};
        preferLocalBuild = true;
        allowSubstitutes = true;
        passthru = {inherit addonId;};
        buildCommand = ''
          dst="$out/share/mozilla/extensions/{ec8030f7-c20a-464f-9b0e-13a3a9e97384}"
          mkdir -p "$dst"
          install -v -m644 "$src" "$dst/${addonId}.xpi"
        '';
      };

    dkim-verifier = buildThunderbirdAddon {
      pname = "dkim-verifier";
      version = "6.2.0";
      addonId = "dkim_verifier@pl";
      url = "https://addons.thunderbird.net/thunderbird/downloads/file/1041596/dkim_verifier-6.2.0-tb.xpi";
      sha256 = "d60bcfdcc22fe82e8f1f63e4066aab8561fa509526b87dc3ca4b90f601985c53";
    };
  in {
    programs.thunderbird = {
      enable = true;

      settings = {
        # telemetry
        "datareporting.policy.dataSubmissionEnabled" = false;
        "datareporting.healthreport.uploadEnabled" = false;
        "toolkit.telemetry.unified" = false;
        "toolkit.telemetry.enabled" = false;
        "toolkit.telemetry.server" = "data:,";
        "toolkit.telemetry.archive.enabled" = false;
        "toolkit.telemetry.newProfilePing.enabled" = false;
        "toolkit.telemetry.shutdownPingSender.enabled" = false;
        "toolkit.telemetry.updatePing.enabled" = false;
        "toolkit.telemetry.bhrPing.enabled" = false;
        "toolkit.telemetry.firstShutdownPing.enabled" = false;
        "toolkit.coverage.opt-out" = true;

        # crash reports
        "breakpad.reportURL" = "";
        "browser.tabs.crashReporting.sendReport" = false;
        "browser.crashReports.unsubmittedCheck.autoSubmit2" = false;

        # privacy
        "mailnews.headers.sendUserAgent" = false;
        "mail.suppress_content_language" = true;
        "mailnews.message_display.disable_remote_image" = true;
        "network.http.referer.XOriginTrimmingPolicy" = 2;
        "network.dns.disablePrefetch" = true;
        "network.prefetch-next" = false;
        "dom.security.https_only_mode" = true;
        "mail.phishing.detection.enabled" = true;

        # ui
        "extensions.getAddons.showPane" = false;
        "extensions.htmlaboutaddons.recommendations.enabled" = false;
        "browser.discovery.enabled" = false;
        "privacy.donottrackheader.enabled" = true;
        "middlemouse.paste" = false;
      };

      profiles.default = {
        isDefault = true;

        extensions = [
          dkim-verifier
        ];

        settings = {
          "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
          "extensions.autoDisableScopes" = 0;
          "mail.uidensity" = 1;
          "mailnews.start_page.enabled" = false;
          "spellchecker.dictionary" = "en-US";
          "layout.spellcheckDefault" = 2;

          # sort newest first, unthreaded
          "mailnews.default_sort_order" = 2;
          "mailnews.default_sort_type" = 18;
          "mailnews.default_view_flags" = 0;

          # threading by headers only, not subject line
          "mail.strict_threading" = true;
          "mail.thread_without_re" = false;

          # compose
          "mailnews.sendInBackground" = true;
          "mail.compose.attachment_reminder" = true;
          "mail.content_disposition_type" = 1;

          # mark as read after 3s delay
          "mailnews.mark_message_read.auto" = true;
          "mailnews.mark_message_read.delay" = true;
          "mailnews.mark_message_read.delay.interval" = 3;

          # check all imap folders, not just inbox
          "mail.server.default.check_all_folders_for_new" = true;

          # double-click opens in new tab
          "mail.openMessageBehavior" = 2;
          "mail.showCondensedAddresses" = false;
          "mailnews.attachments.display.start_expanded" = true;

          # sanitized html rendering
          "mailnews.display.html_as" = 3;

          # performance
          "mail.db.idle_limit" = 30000000;
          "mail.db.max_open" = 15;
        };

        userChrome = ''
          :root {
            --lwt-accent-color: ${c.bg} !important;
            --toolbar-bgcolor: ${c.bg} !important;
            --lwt-toolbarbutton-icon-fill: ${c.text} !important;
            --listbox-selected-background: ${c.accent} !important;
            --listbox-selected-color: ${c.bg} !important;
            --listbox-hover-background: ${c.mantle} !important;
            --listbox-color: ${c.text} !important;
            --tab-shadow: 0 0 4px #111;
            --toolbar-field-background-color: ${c.mantle} !important;
          }

          #messengerWindow,
          #folderPaneBox,
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
          #folderPaneBox {
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

          /* modern-thunderbird buttons + search */
          .toolbarbutton-1,
          .searchBox,
          .themeableSearchBox {
            border: none !important;
            border-radius: 5px !important;
            height: 31px !important;
          }
          .contentTabUrlInput {
            height: 26px !important;
          }
          #urlbar-background {
            border: none;
            box-shadow: none !important;
          }

          /* modern-thunderbird popups */
          .panel-arrowbox {
            display: none;
          }
          .panel-arrowcontent {
            padding: 5px !important;
            border-radius: 5px;
            border: none;
          }

          /* folder pane selection */
          #folderTree tr.selected {
            background-color: ${c.accent} !important;
            color: ${c.bg} !important;
          }
          #folderTree tr:hover:not(.selected) {
            background-color: ${c.mantle} !important;
          }

          /* thread cards view, TB 128+ paints .card-container not the row */
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

    xdg.mimeApps.defaultApplications = {
      "x-scheme-handler/mailto" = "thunderbird.desktop";
      "message/rfc822" = "thunderbird.desktop";
      "x-scheme-handler/mid" = "thunderbird.desktop";
    };
  };
}
