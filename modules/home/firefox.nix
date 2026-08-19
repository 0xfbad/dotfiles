_: {
  flake.modules.homeManager.firefox =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      c = config.colors;
    in
    {
      # GetLegacyOrXDGHomePath prefers ~/.mozilla/firefox when it exists and ignores the xdg path
      home.activation.warnLegacyMozilla = lib.hm.dag.entryBefore [ "writeBoundary" ] ''
        if [ -e "$HOME/.mozilla/firefox" ]; then
          echo "WARNING: ~/.mozilla/firefox exists, firefox will ignore the XDG profile" >&2
        fi
      '';

      programs.firefox = {
        enable = true;
        configPath = "${config.xdg.configHome}/mozilla/firefox";
        policies = {
          DisableTelemetry = true;
          DisableFirefoxStudies = true;
          DisableRemoteImprovements = true;
          DisableFirefoxAccounts = true;
          DisableProfileImport = true;
          DisableFirefoxScreenshots = true;
          DontCheckDefaultBrowser = true;
          EnableTrackingProtection = {
            Value = true;
            Locked = true;
            Category = "strict";
            EmailTracking = true;
            SuspectedFingerprinting = true;
            BaselineExceptions = true;
            ConvenienceExceptions = false;
          };
          HttpsOnlyMode = "force_enabled";
          DNSOverHTTPS = {
            Enabled = false;
            Locked = true;
          };
          PostQuantumKeyAgreementEnabled = true;
          PasswordManagerEnabled = false;
          OfferToSaveLogins = false;
          AutofillAddressEnabled = false;
          AutofillCreditCardEnabled = false;
          AIControls = {
            Default = {
              Value = "blocked";
              Locked = true;
            };
          };
          FirefoxSuggest = {
            WebSuggestions = false;
            SponsoredSuggestions = false;
            OnlineEnabled = false;
            Locked = true;
          };
          UserMessaging = {
            ExtensionRecommendations = false;
            FeatureRecommendations = false;
            UrlbarInterventions = false;
            SkipOnboarding = true;
            MoreFromMozilla = false;
            FirefoxLabs = false;
            Locked = true;
          };
          FirefoxHome = {
            Search = true;
            TopSites = false;
            SponsoredTopSites = false;
            Highlights = false;
            Stories = false;
            SponsoredStories = false;
            Weather = false;
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
              private_browsing = true;
            };
            "keepassxc-browser@keepassxc.org" = {
              install_url = "https://addons.mozilla.org/firefox/downloads/latest/keepassxc-browser/latest.xpi";
              installation_mode = "force_installed";
              default_area = "navbar";
              private_browsing = true;
            };
            "addon@darkreader.org" = {
              install_url = "https://addons.mozilla.org/firefox/downloads/latest/darkreader/latest.xpi";
              installation_mode = "force_installed";
              default_area = "navbar";
              private_browsing = true;
            };
            "firefox@tampermonkey.net" = {
              install_url = "https://addons.mozilla.org/firefox/downloads/latest/tampermonkey/latest.xpi";
              installation_mode = "force_installed";
              default_area = "navbar";
              private_browsing = true;
            };
            "myallychou@gmail.com" = {
              install_url = "https://addons.mozilla.org/firefox/downloads/latest/youtube-recommended-videos/latest.xpi";
              installation_mode = "force_installed";
              default_area = "menupanel";
              private_browsing = true;
            };
            "{a6c4a591-f1b2-4f03-b3ff-767e5bedf4e7}" = {
              install_url = "https://addons.mozilla.org/firefox/downloads/latest/user-agent-string-switcher/latest.xpi";
              installation_mode = "force_installed";
              default_area = "navbar";
              private_browsing = true;
            };
            "{DEBA3021-9876-4702-89BA-42D095339A0A}" = {
              install_url = "https://addons.mozilla.org/firefox/downloads/latest/disable-page-visibility/latest.xpi";
              installation_mode = "force_installed";
              default_area = "menupanel";
              private_browsing = true;
            };
            "{7343f7d1-e6ef-4d8a-8449-d4c18850f559}" = {
              install_url = "https://addons.mozilla.org/firefox/downloads/latest/clipboard2file/latest.xpi";
              installation_mode = "force_installed";
              default_area = "menupanel";
              private_browsing = true;
            };
          };
        };
        profiles.default = {
          isDefault = true;
          search = {
            force = true;
            default = "ddg";
            order = [
              "ddg"
              "Nix Packages"
              "NixOS Options"
              "NixOS Wiki"
              "Home Manager Options"
            ];
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
                        name = "channel";
                        value = "unstable";
                      }
                      {
                        name = "query";
                        value = "{searchTerms}";
                      }
                    ];
                  }
                ];
                icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
                definedAliases = [ "@np" ];
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
                definedAliases = [ "@no" ];
              };
              "NixOS Wiki" = {
                urls = [ { template = "https://wiki.nixos.org/w/index.php?search={searchTerms}"; } ];
                icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
                definedAliases = [ "@nw" ];
              };
              "Home Manager Options" = {
                urls = [ { template = "https://home-manager-options.extranix.com/?query={searchTerms}"; } ];
                definedAliases = [ "@hm" ];
              };
              "bing".metaData.hidden = true;
              "amazondotcom-us".metaData.hidden = true;
              "ebay".metaData.hidden = true;
              "perplexity".metaData.hidden = true;
            };
          };
          settings = {
            "toolkit.telemetry.enabled" = false;
            "toolkit.telemetry.unified" = false;
            "toolkit.telemetry.archive.enabled" = false;
            "toolkit.telemetry.server" = "data:,";
            "toolkit.coverage.opt-out" = true;
            "toolkit.telemetry.coverage.opt-out" = true;
            "toolkit.coverage.endpoint.base" = "";
            "datareporting.healthreport.uploadEnabled" = false;
            "datareporting.policy.dataSubmissionEnabled" = false;
            # normandy and shield push remote experiments, https://mozilla.github.io/normandy/
            "app.shield.optoutstudies.enabled" = false;
            "app.normandy.enabled" = false;
            "app.normandy.api_url" = "";
            "breakpad.reportURL" = "";
            "browser.tabs.crashReporting.sendReport" = false;
            "browser.crashReports.unsubmittedCheck.autoSubmit2" = false;

            "browser.newtabpage.enabled" = false;
            "browser.startup.homepage" = "about:blank";
            "browser.newtabpage.activity-stream.telemetry" = false;
            "browser.newtabpage.activity-stream.feeds.section.topstories" = false;
            "browser.newtabpage.activity-stream.feeds.section.highlights" = false;
            "browser.newtabpage.activity-stream.showSponsored" = false;
            "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
            "browser.newtabpage.activity-stream.default.sites" = "";
            "browser.newtabpage.activity-stream.feeds.topsites" = false;
            "browser.newtabpage.activity-stream.improvesearch.topSiteSearchShortcuts" = false;
            "browser.newtabpage.activity-stream.showWeather" = false;
            "browser.newtabpage.activity-stream.system.showWeather" = false;
            "browser.newtab.preload" = false;

            # the strict category itself comes from the EnableTrackingProtection policy
            "privacy.purge_trackers.enabled" = true;
            "privacy.globalprivacycontrol.enabled" = true;
            "privacy.globalprivacycontrol.functionality.enabled" = true;
            # https only mode fires a plaintext background probe on slow upgrades, leaking the hostname
            "dom.security.https_only_mode_send_http_background_request" = false;

            "network.dns.disablePrefetch" = true;
            "network.dns.disablePrefetchFromHTTPS" = true;
            "network.prefetch-next" = false;
            "network.http.speculative-parallel-limit" = 0;

            # webrtc ip leak prevention
            "media.peerconnection.ice.default_address_only" = true;
            # 0rtt data can be replayed
            "security.tls.enable_0rtt_data" = false;
            # prevents unicode domain spoofing
            "network.IDN_show_punycode" = true;

            # drm, needed for netflix and spotify web
            "media.eme.enabled" = true;
            "media.gmp-widevinecdm.enabled" = true;

            # keep the old ctrl+h history panel instead of the sidebar redesign
            "sidebar.revamp" = false;
            "sidebar.verticalTabs" = false;

            "browser.ml.enable" = false;
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
            "browser.tabs.groups.smart.userEnabled" = false;
            "browser.ml.chat.shortcuts.smartwindow" = false;
            "browser.smartwindow.memories.generateFromHistory" = false;
            "browser.smartwindow.memories.generateFromConversation" = false;

            # keepassxc handles passwords and autofill
            "signon.autofillForms" = false;
            "signon.generation.enabled" = false;
            "signon.management.page.breach-alerts.enabled" = false;
            "signon.firefoxRelay.feature" = "";
            "extensions.formautofill.addresses.supported" = "off";
            "extensions.formautofill.creditCards.supported" = "off";
            "browser.formfill.enable" = false;

            "browser.urlbar.quicksuggest.enabled" = false;
            "browser.urlbar.suggest.quicksuggest.all" = false;
            "browser.urlbar.suggest.quicksuggest.sponsored" = false;
            # pre fx146 name for suggest.quicksuggest.all, kept for esr and downgrades
            "browser.urlbar.suggest.quicksuggest.nonsponsored" = false;
            "browser.urlbar.quicksuggest.online.enabled" = false;
            "browser.urlbar.quicksuggest.contextualOptIn" = false;
            "browser.urlbar.suggest.realtimeOptIn" = false;
            "browser.urlbar.quicksuggest.mlEnabled" = false;
            # gate list tracks arkenfox v144
            "browser.urlbar.trending.featureGate" = false;
            "browser.urlbar.addons.featureGate" = false;
            "browser.urlbar.mdn.featureGate" = false;
            "browser.urlbar.yelp.featureGate" = false;
            "browser.urlbar.yelpRealtime.featureGate" = false;
            "browser.urlbar.amp.featureGate" = false;
            "browser.urlbar.wikipedia.featureGate" = false;
            "browser.urlbar.market.featureGate" = false;
            "browser.urlbar.importantDates.featureGate" = false;
            "browser.urlbar.fakespot.featureGate" = false;
            "browser.urlbar.flightStatus.featureGate" = false;
            "browser.urlbar.sports.featureGate" = false;
            "places.semanticHistory.featureGate" = false;

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

            "extensions.htmlaboutaddons.recommendations.enabled" = false;
            "extensions.getAddons.showPane" = false;
            "browser.discovery.enabled" = false;

            # apis that leak info
            # gamepad api allows usb device enumeration
            "dom.gamepad.enabled" = false;
            # beacon carries async analytics transfers
            "beacon.enabled" = false;
            "browser.urlbar.weather.featureGate" = false;

            # 0 dark, 1 light, 2 auto, sites serve their own dark theme
            "layout.css.prefers-color-scheme.content-override" = 0;
            # force gpu rendering even on blocklisted hardware
            "gfx.webrender.all" = true;
            "browser.compactmode.show" = true;

            # session writes every 30min instead of 15s, saves ssd writes
            "browser.sessionstore.interval" = 1800000;

            "browser.aboutConfig.showWarning" = false;
            "browser.disableResetPrompt" = true;
            "browser.toolbars.bookmarks.visibility" = "always";
            "browser.bookmarks.addedImportButton" = false;
          };

          userChrome = ''
            :root {
              --toolbar-background-color: ${c.bg} !important;
              --toolbox-background-color: ${c.bg} !important;
              --lwt-accent-color: ${c.bg} !important;
              --toolbarbutton-icon-fill: ${c.text} !important;
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
            #sidebar-container,
            #sidebar-launcher-splitter {
              display: none !important;
            }
            #firefox-view-button {
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
