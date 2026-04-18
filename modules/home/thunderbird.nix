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

    send-later = buildThunderbirdAddon {
      pname = "send-later";
      version = "10.7.8";
      addonId = "sendlater3@kamens.us";
      url = "https://addons.thunderbird.net/thunderbird/downloads/file/1042516/send_later-10.7.8-tb.xpi?src=";
      sha256 = "c6290ebbc8a22431d9cd59d12a62835dbd0df749bba6ff162c07b4e84fc503f0";
    };

    importexporttools-ng = buildThunderbirdAddon {
      pname = "importexporttools-ng";
      version = "14.1.18";
      addonId = "ImportExportToolsNG@cleidigh.kokkini.net";
      url = "https://addons.thunderbird.net/thunderbird/downloads/file/1046111/importexporttools_ng-14.1.18-tb.xpi";
      sha256 = "9fcb20898931677acce95cff3d37f2388abd378cc2b937c8914302e14bebb5bb";
    };

    quick-folder-move = buildThunderbirdAddon {
      pname = "quick-folder-move";
      version = "3.3.0";
      addonId = "quickmove@mozilla.kewis.ch";
      url = "https://addons.thunderbird.net/thunderbird/downloads/file/1039502/quick_folder_move-3.3.0-tb.xpi";
      sha256 = "a54b8a839ad843c2775f1372155b6a9ef529ef899bce1799768791084cebba13";
    };

    thunderbird-conversations = buildThunderbirdAddon {
      pname = "thunderbird-conversations";
      version = "4.3.9";
      addonId = "gconversation@xulforum.org";
      url = "https://addons.thunderbird.net/thunderbird/downloads/file/1045419/thunderbird_conversations-4.3.9-tb.xpi";
      sha256 = "55d2dc73743f6606812ffcd3e1941ba267eb3f9d93c414c87210eef3c5455c2a";
    };

    bordercolors-d = buildThunderbirdAddon {
      pname = "bordercolors-d";
      version = "2025.10.1";
      addonId = "bordercolors-d@addonsdev.mozilla.org";
      url = "https://addons.thunderbird.net/thunderbird/downloads/file/1042296/bordercolors_d-2025.10.1-tb.xpi";
      sha256 = "002974b916b762021d6a6565469a7a2e4ac6f0c7a58cf5598b6242d389ca0662";
    };

    correct-identity = buildThunderbirdAddon {
      pname = "correct-identity";
      version = "2.6.6";
      addonId = "{47ef7cc0-2201-11da-8cd6-0800200c9a66}";
      url = "https://addons.thunderbird.net/thunderbird/downloads/file/1045334/correct_identity-2.6.6-tb.xpi";
      sha256 = "303cbca4680f3932d5c1a8b2b848e83f4db59987b2dbf4286a32706302d45cc3";
    };

    expression-search-ng = buildThunderbirdAddon {
      pname = "expression-search-ng";
      version = "4.8.34";
      addonId = "expressionsearch@opto.one";
      url = "https://addons.thunderbird.net/thunderbird/downloads/file/1045921/expression_power_messagecalendar_search_ng-4.8.34-tb.xpi";
      sha256 = "90b63fd9080972f0de57697782b6db85cfad9314e116ad6e9a26179b2bb3c9da";
    };

    filtaquilla = buildThunderbirdAddon {
      pname = "filtaquilla";
      version = "6.1";
      addonId = "filtaquilla@mesquilla.com";
      url = "https://addons.thunderbird.net/thunderbird/downloads/file/1044060/filtaquilla-6.1-tb.xpi";
      sha256 = "a4f9e6422ec7c6e8086489a0cae9dd4939f76fcf2134e8bdcc902ac1cfc653f7";
    };

    dkim-verifier = buildThunderbirdAddon {
      pname = "dkim-verifier";
      version = "6.2.0";
      addonId = "dkim_verifier@pl";
      url = "https://addons.thunderbird.net/thunderbird/downloads/file/1041596/dkim_verifier-6.2.0-tb.xpi";
      sha256 = "d60bcfdcc22fe82e8f1f63e4066aab8561fa509526b87dc3ca4b90f601985c53";
    };

    removedupes = buildThunderbirdAddon {
      pname = "removedupes";
      version = "0.6.4";
      addonId = "{a300a000-5e21-4ee0-a115-9ec8f4eaa92b}";
      url = "https://addons.thunderbird.net/thunderbird/downloads/file/1042514/remove_duplicate_messages-0.6.4-tb.xpi";
      sha256 = "353f22c3ba527b7a6a752b3afdd6f51817b965964ee935c57626cf09d51a0348";
    };

    betterunsubscribe = buildThunderbirdAddon {
      pname = "betterunsubscribe";
      version = "2.8.0";
      addonId = "{4753278b-acea-4b2b-a111-1fc9450d239d}";
      url = "https://addons.thunderbird.net/thunderbird/downloads/file/1044595/betterunsubscribe-2.8.0-tb.xpi";
      sha256 = "bbaf1c9e0fbcaaaaf0771b9e657bcb6dd7e090cd5f5e4099c55293520fca836a";
    };

    compact-headers = buildThunderbirdAddon {
      pname = "compact-headers";
      version = "5.12";
      addonId = "compactHeaders@dillinger";
      url = "https://addons.thunderbird.net/thunderbird/downloads/file/1045745/compact_headers-5.12-tb.xpi";
      sha256 = "72b29fd3bb3536358f6bee19b0d65685f04b06df84a80829b1842bbdd8b5ef0f";
    };

    quickfilters = buildThunderbirdAddon {
      pname = "quickfilters";
      version = "6.12.2";
      addonId = "quickFilters@axelg.com";
      url = "https://addons.thunderbird.net/thunderbird/downloads/file/1045995/quickfilters-6.12.2-tb.xpi";
      sha256 = "91f4059e239fe5e09764f5515f98f07023f9d48f36ffe1258f187b4712a44441";
    };

    flex-confirm-mail = buildThunderbirdAddon {
      pname = "flex-confirm-mail";
      version = "4.2.8";
      addonId = "flexible-confirm-mail-progressive@clear-code.com";
      url = "https://addons.thunderbird.net/thunderbird/downloads/file/1042546/flexconfirmmail-4.2.8-tb.xpi";
      sha256 = "da1a9c0e4a8b3c06edd45a36aead9a2e54bc1afc5ba65ab47ab1c24e60a8ce6d";
    };

    tbkeys-lite = buildThunderbirdAddon {
      pname = "tbkeys-lite";
      version = "2.4.3";
      addonId = "tbkeys-lite@addons.thunderbird.net";
      url = "https://addons.thunderbird.net/thunderbird/downloads/file/1044591/tbkeys_lite-2.4.3-tb.xpi";
      sha256 = "42cdfeae8e4e83725a4442881c0f00ff4759aa03dcd7d71d55a200058e2a1650";
    };

    remindme = buildThunderbirdAddon {
      pname = "remindme";
      version = "2.30";
      addonId = "RemindMed@cparg.de";
      url = "https://addons.thunderbird.net/thunderbird/downloads/file/1043681/remindme-2.30-tb.xpi";
      sha256 = "0b9800cc1e05f440022209e529ff949c6ce3da7512cafe3d634f1c5b6ef82879";
    };

    allow-html-temp = buildThunderbirdAddon {
      pname = "allow-html-temp";
      version = "10.1.1";
      addonId = "{532269cf-a10e-4396-8613-b5d9a9a516d4}";
      url = "https://addons.thunderbird.net/thunderbird/downloads/file/1041712/allow_html_temp-10.1.1-tb.xpi";
      sha256 = "f084775d8eafc4009f785fa2fef36dc0182673a3fdb2fd2e9ff239198d53ca5b";
    };

    nostalgy-ng = buildThunderbirdAddon {
      pname = "nostalgy-ng";
      version = "5.0.3";
      addonId = "nostalgy@opto.one";
      url = "https://addons.thunderbird.net/thunderbird/downloads/file/1043785/nostalgy_emails_verwalten_suchen_archivieren-5.0.3-tb.xpi";
      sha256 = "c64703118bce00be3dc830f96e8ec3927fe2e6d2f720e12ca6d138f7d86bc378";
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
          send-later
          importexporttools-ng
          quick-folder-move
          thunderbird-conversations
          bordercolors-d
          correct-identity
          expression-search-ng
          filtaquilla
          dkim-verifier
          removedupes
          betterunsubscribe
          compact-headers
          quickfilters
          flex-confirm-mail
          tbkeys-lite
          remindme
          allow-html-temp
          nostalgy-ng
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
          /* selected tab */
          .tabmail-tab[selected] {
            background-color: ${c.accent} !important;
            color: ${c.bg} !important;
          }
          /* selected folder/thread row */
          #folderTree tr.selected,
          #threadTree tr.selected {
            background-color: ${c.accent} !important;
            color: ${c.bg} !important;
          }
          /* hover */
          #folderTree tr:hover:not(.selected),
          #threadTree tr:hover:not(.selected) {
            background-color: ${c.mantle} !important;
          }
          /* text colors */
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
