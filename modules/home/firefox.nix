_: {
  flake.homeModules.firefox = {
    pkgs,
    config,
    ...
  }: let
    c = config.colors;
  in {
    programs.firefox = {
      enable = true;
      policies = {
        DisableTelemetry = true;
        DisableFirefoxStudies = true;
        DisablePocket = true;
        DisableFirefoxAccounts = true;
        DisableProfileImport = true;
        DontCheckDefaultBrowser = true;
        EnableTrackingProtection = {
          Value = true;
          Locked = true;
          Cryptomining = true;
          Fingerprinting = true;
        };
        FirefoxHome = {
          Search = true;
          TopSites = false;
          SponsoredTopSites = false;
          Highlights = false;
          Pocket = false;
          SponsoredPocket = false;
          Snippets = false;
          Locked = true;
        };
        NoDefaultBookmarks = true;
        DisplayBookmarksToolbar = "always";
        DisplayMenuBar = "default-off";
        ShowHomeButton = false;
        ExtensionSettings = {
          "uBlock0@raymondhill.net" = {
            install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
            installation_mode = "force_installed";
            default_area = "navbar";
          };
          "{446900e4-71c2-419f-a6a7-df9c091e268b}" = {
            install_url = "https://addons.mozilla.org/firefox/downloads/latest/bitwarden-password-manager/latest.xpi";
            installation_mode = "force_installed";
            default_area = "navbar";
          };
          "addon@darkreader.org" = {
            install_url = "https://addons.mozilla.org/firefox/downloads/latest/darkreader/latest.xpi";
            installation_mode = "force_installed";
            default_area = "navbar";
          };
          "firefox@tampermonkey.net" = {
            install_url = "https://addons.mozilla.org/firefox/downloads/latest/tampermonkey/latest.xpi";
            installation_mode = "force_installed";
            default_area = "navbar";
          };
          "myallychou@gmail.com" = {
            install_url = "https://addons.mozilla.org/firefox/downloads/latest/youtube-recommended-videos/latest.xpi";
            installation_mode = "force_installed";
            default_area = "menupanel";
          };
          "{a6c4a591-f1b2-4f03-b3ff-767e5bedf4e7}" = {
            install_url = "https://addons.mozilla.org/firefox/downloads/latest/user-agent-string-switcher/latest.xpi";
            installation_mode = "force_installed";
            default_area = "navbar";
          };
          "{DEBA3021-9876-4702-89BA-42D095339A0A}" = {
            install_url = "https://addons.mozilla.org/firefox/downloads/latest/disable-page-visibility/latest.xpi";
            installation_mode = "force_installed";
            default_area = "menupanel";
          };
          "{7343f7d1-e6ef-4d8a-8449-d4c18850f559}" = {
            install_url = "https://addons.mozilla.org/firefox/downloads/latest/clipboard2file/latest.xpi";
            installation_mode = "force_installed";
            default_area = "menupanel";
          };
        };
      };
      profiles.default = {
        isDefault = true;
        search = {
          force = true;
          default = "ddg";
          engines = {
            "Nix Packages" = {
              urls = [
                {
                  template = "https://search.nixos.org/packages";
                  params = [
                    {
                      name = "type";
                      value = "packages";
                    }
                    {
                      name = "query";
                      value = "{searchTerms}";
                    }
                  ];
                }
              ];
              icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
              definedAliases = ["@np"];
            };
            "NixOS Options" = {
              urls = [
                {
                  template = "https://search.nixos.org/options";
                  params = [
                    {
                      name = "query";
                      value = "{searchTerms}";
                    }
                  ];
                }
              ];
              icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
              definedAliases = ["@no"];
            };
            "NixOS Wiki" = {
              urls = [{template = "https://wiki.nixos.org/w/index.php?search={searchTerms}";}];
              icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
              definedAliases = ["@nw"];
            };
            "Home Manager Options" = {
              urls = [{template = "https://home-manager-options.extranix.com/?query={searchTerms}";}];
              definedAliases = ["@hm"];
            };
            "bing".metaData.hidden = true;
            "amazondotcom-us".metaData.hidden = true;
            "ebay".metaData.hidden = true;
            "perplexity".metaData.hidden = true;
          };
        };
        settings = {
          # telemetry, studies, crash reports
          # https://wiki.mozilla.org/Telemetry
          "toolkit.telemetry.enabled" = false;
          "toolkit.telemetry.unified" = false;
          "toolkit.telemetry.archive.enabled" = false;
          "toolkit.telemetry.server" = "data:,";
          "toolkit.telemetry.coverage.opt-out" = true;
          "toolkit.coverage.opt-out" = true;
          "toolkit.coverage.endpoint.base" = "";
          "datareporting.healthreport.uploadEnabled" = false;
          "datareporting.healthreport.service.enabled" = false;
          "datareporting.policy.dataSubmissionEnabled" = false;
          "browser.ping-centre.telemetry" = false;
          # https://mozilla.github.io/normandy/
          "app.shield.optoutstudies.enabled" = false;
          "app.normandy.enabled" = false;
          "app.normandy.api_url" = "";
          "experiments.supported" = false;
          "experiments.enabled" = false;
          "experiments.manifest.uri" = "";
          # crash reports
          "breakpad.reportURL" = "";
          "browser.tabs.crashReporting.sendReport" = false;
          "browser.crashReports.unsubmittedCheck.autoSubmit2" = false;

          # pocket (kill it)
          "extensions.pocket.enabled" = false;
          "extensions.pocket.site" = "";
          "extensions.pocket.oAuthConsumerKey" = "";
          "extensions.pocket.api" = "";

          # new tab page (custom startpage)
          "browser.newtabpage.enabled" = false;
          "browser.startup.homepage" = "about:blank";
          "browser.newtabpage.activity-stream.enabled" = false;
          "browser.newtabpage.activity-stream.feeds.telemetry" = false;
          "browser.newtabpage.activity-stream.telemetry" = false;
          "browser.newtabpage.activity-stream.feeds.section.topstories" = false;
          "browser.newtabpage.activity-stream.feeds.section.highlights" = false;
          "browser.newtabpage.activity-stream.section.highlights.includePocket" = false;
          "browser.newtabpage.activity-stream.showSponsored" = false;
          "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
          "browser.newtabpage.activity-stream.default.sites" = "";
          "browser.newtabpage.activity-stream.feeds.topsites" = false;
          "browser.newtabpage.activity-stream.improvesearch.topSiteSearchShortcuts" = false;
          "browser.newtabpage.activity-stream.showWeather" = false;
          "browser.newtabpage.activity-stream.system.showWeather" = false;
          "browser.newtabpage.enhanced" = false;
          "browser.newtab.preload" = false;

          # tracking protection (strict mode, purge trackers)
          "privacy.trackingprotection.enabled" = true;
          "privacy.trackingprotection.socialtracking.enabled" = true;
          "browser.contentblocking.category" = "strict";
          "privacy.purge_trackers.enabled" = true;
          "privacy.donottrackheader.enabled" = true;
          "privacy.donottrackheader.value" = 1;
          "privacy.globalprivacycontrol.enabled" = true;
          "privacy.globalprivacycontrol.functionality.enabled" = true;

          # network (disable prefetch, speculative connections, tighten dns cache)
          "network.dns.disablePrefetch" = true;
          "network.dns.disablePrefetchFromHTTPS" = true;
          "network.prefetch-next" = false;
          "network.predictor.enabled" = false;
          "network.predictor.enable-prefetch" = false;
          "network.http.speculative-parallel-limit" = 0;
          "network.dnsCacheExpiration" = 0;
          # enable QUIC/HTTP3
          "network.http.http3.enabled" = true;

          # security
          # https only mode
          "dom.security.https_only_mode" = true;
          # webrtc leak prevention (only expose default route)
          "media.peerconnection.ice.default_address_only" = true;
          # TLS 0-RTT replay attack prevention
          "security.tls.enable_0rtt_data" = false;
          "security.pki.sha1_enforcement_level" = 1;
          # show punycode to prevent unicode domain spoofing
          "network.IDN_show_punycode" = true;

          # drm (needed for netflix, spotify web, etc)
          "media.eme.enabled" = true;
          "media.gmp-widevinecdm.enabled" = true;

          # sidebar (disable new redesign, keep old ctrl+h history panel)
          "sidebar.revamp" = false;
          "sidebar.verticalTabs" = false;

          # ai features (kill every single one)
          "browser.ml.enable" = false;
          "browser.ml.assistant.enabled" = false;
          "browser.ml.chat.enabled" = false;
          "browser.ml.chat.sidebar" = false;
          "browser.ml.chat.shortcuts" = false;
          "browser.ml.chat.page" = false;
          "browser.ml.chat.page.footerBadge" = false;
          "browser.ml.chat.page.menuBadge" = false;
          "browser.ml.chat.menu" = false;
          "browser.ml.linkPreview.enabled" = false;
          "browser.ml.pageAssist.enabled" = false;
          "extensions.ml.enabled" = false;
          "browser.tabs.groups.smart.enabled" = false;

          # passwords and autofill (bitwarden handles all of this)
          "signon.rememberSignons" = false;
          "signon.autofillForms" = false;
          "signon.generation.enabled" = false;
          "signon.management.page.breach-alerts.enabled" = false;
          "signon.firefoxRelay.feature" = "";
          "extensions.formautofill.addresses.enabled" = false;
          "extensions.formautofill.addresses.supported" = "";
          "extensions.formautofill.creditCards.enabled" = false;
          "extensions.formautofill.creditCards.available" = false;
          "extensions.formautofill.creditCards.supported" = "";
          "extensions.formautofill.heuristics.enabled" = false;
          "browser.formfill.enable" = false;
          "extensions.formautofill.available" = "off";

          # urlbar (no suggestions, no sponsored, no trending, show full urls)
          "browser.urlbar.suggest.quicksuggest.sponsored" = false;
          "browser.urlbar.suggest.quicksuggest.nonsponsored" = false;
          "browser.urlbar.quicksuggest.enabled" = false;
          "browser.urlbar.suggest.pocket" = false;
          "browser.urlbar.suggest.trending" = false;
          "browser.urlbar.suggest.weather" = false;
          "browser.urlbar.suggest.mdn" = false;
          "browser.urlbar.suggest.addons" = false;
          "browser.urlbar.suggest.yelp" = false;
          "browser.urlbar.suggest.topsites" = false;
          "browser.urlbar.suggest.searches" = false;
          "browser.urlbar.trimURLs" = false;
          "browser.urlbar.dnsResolveSingleWordsAfterSearch" = 0;
          "browser.search.suggest.enabled" = false;

          # anti-slop (recommendations, cfr, discovery)
          "browser.newtabpage.activity-stream.asrouter.userprefs.cfr.addons" = false;
          "browser.newtabpage.activity-stream.asrouter.userprefs.cfr.features" = false;
          "extensions.htmlaboutaddons.recommendations.enabled" = false;
          "extensions.htmlaboutaddons.discover.enabled" = false;
          "extensions.getAddons.showPane" = false;
          "extensions.screenshots.disabled" = true;
          "browser.discovery.enabled" = false;
          "browser.aboutwelcome.enabled" = false;

          # firefox view (kill it)
          "browser.tabs.firefox-view" = false;
          "browser.tabs.firefox-view-next" = false;

          # disable apis that leak info or are useless
          # battery status api
          "dom.battery.enabled" = false;
          # gamepad api (prevents USB device enumeration)
          "dom.gamepad.enabled" = false;
          # beacon api (async analytics transfers)
          "beacon.enabled" = false;
          # ping tracking
          "browser.send_pings" = false;
          # ad attribution api
          "dom.private-attribution.submission.enabled" = false;
          # weather in urlbar
          "browser.urlbar.weather.featureGate" = false;

          # performance
          # write session data every 30min instead of 15s (saves SSD writes)
          "browser.sessionstore.interval" = "1800000";
          # gpu accelerated rendering
          "gfx.webrender.all" = true;
          # compact ui mode
          "browser.compactmode.show" = true;

          # misc
          "browser.shell.checkDefaultBrowser" = false;
          "browser.aboutConfig.showWarning" = false;
          "browser.disableResetPrompt" = true;
          "browser.fixup.alternate.enabled" = false;
          "browser.toolbars.bookmarks.visibility" = "always";
          "browser.bookmarks.addedImportButton" = false;
          "identity.fxaccounts.enabled" = false;
          "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
        };

        userChrome = ''
          :root {
            --toolbar-bgcolor: ${c.bg} !important;
            --lwt-accent-color: ${c.bg} !important;
            --lwt-toolbarbutton-icon-fill: ${c.text} !important;
          }
          #navigator-toolbox,
          #TabsToolbar,
          #PersonalToolbar,
          #nav-bar {
            background-color: ${c.bg} !important;
          }
          .tabbrowser-tab[selected] .tab-background {
            background-color: ${c.accent} !important;
          }
          .tabbrowser-tab[selected] .tab-label {
            color: ${c.bg} !important;
          }
          .tabbrowser-tab:not([selected]) .tab-background:hover {
            background-color: ${c.mantle} !important;
          }
          #sidebar-main,
          #sidebar-launcher-splitter {
            display: none !important;
          }
        '';

        userContent = ''
          @-moz-document url("about:newtab"), url("about:home"), url("about:blank") {
            body { background-color: ${c.bg} !important; }
          }
        '';
      };
    };
  };
}
