_: {
  flake.homeModules.firefox = {pkgs, ...}: {
    programs.firefox = {
      enable = true;
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
          };
        };
        settings = {
          # telemetry
          "toolkit.telemetry.enabled" = false;
          "toolkit.telemetry.unified" = false;
          "toolkit.telemetry.archive.enabled" = false;
          "toolkit.telemetry.server" = "";
          "datareporting.healthreport.uploadEnabled" = false;
          "datareporting.policy.dataSubmissionEnabled" = false;

          # studies and experiments
          "app.shield.optoutstudies.enabled" = false;
          "app.normandy.enabled" = false;
          "app.normandy.api_url" = "";

          # pocket
          "extensions.pocket.enabled" = false;
          "extensions.pocket.site" = "";
          "extensions.pocket.oAuthConsumerKey" = "";
          "extensions.pocket.api" = "";

          # activity stream
          "browser.newtabpage.activity-stream.feeds.telemetry" = false;
          "browser.newtabpage.activity-stream.telemetry" = false;
          "browser.newtabpage.activity-stream.feeds.section.topstories" = false;
          "browser.newtabpage.activity-stream.feeds.section.highlights" = false;
          "browser.newtabpage.activity-stream.section.highlights.includePocket" = false;
          "browser.newtabpage.activity-stream.showSponsored" = false;
          "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
          "browser.newtabpage.activity-stream.default.sites" = "";

          # tracking protection
          "privacy.trackingprotection.enabled" = true;
          "privacy.trackingprotection.socialtracking.enabled" = true;
          "browser.contentblocking.category" = "strict";

          # network privacy
          "network.dns.disablePrefetch" = true;
          "network.prefetch-next" = false;
          "network.predictor.enabled" = false;
          "network.http.speculative-parallel-limit" = 0;

          # webrtc leak prevention
          "media.peerconnection.ice.default_address_only" = true;

          # sidebar (kill it)
          "sidebar.revamp" = false;

          # ai features (kill all of it)
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

          # passwords, autofill, credit cards (bitwarden handles this)
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
          "browser.formfill.enable" = false;
          "extensions.formautofill.available" = "off";

          # weather
          "browser.urlbar.weather.featureGate" = false;
          "browser.newtabpage.activity-stream.showWeather" = false;
          "browser.newtabpage.activity-stream.system.showWeather" = false;

          # shortcuts/topsites on new tab
          "browser.newtabpage.activity-stream.feeds.topsites" = false;
          "browser.newtabpage.activity-stream.improvesearch.topSiteSearchShortcuts" = false;

          # firefox view
          "browser.tabs.firefox-view" = false;
          "browser.tabs.firefox-view-next" = false;

          # anti-slop (sponsored suggestions, recommendations, etc)
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
          "browser.newtabpage.activity-stream.asrouter.userprefs.cfr.addons" = false;
          "browser.newtabpage.activity-stream.asrouter.userprefs.cfr.features" = false;
          "extensions.htmlaboutaddons.recommendations.enabled" = false;
          "extensions.htmlaboutaddons.discover.enabled" = false;
          "extensions.getAddons.showPane" = false;
          "extensions.screenshots.disabled" = true;

          # bookmarks toolbar
          "browser.toolbars.bookmarks.visibility" = "always";

          # userchrome css
          "toolkit.legacyUserProfileCustomizations.stylesheets" = true;

          # sync and accounts
          "identity.fxaccounts.enabled" = false;

          # import button
          "browser.bookmarks.addedImportButton" = false;

          # misc
          "browser.send_pings" = false;
          "dom.battery.enabled" = false;
          "network.IDN_show_punycode" = true;
          "browser.shell.checkDefaultBrowser" = false;
          "browser.search.suggest.enabled" = false;
          "browser.urlbar.suggest.searches" = false;
        };

        # oled black theme
        userChrome = ''
          :root {
            --toolbar-bgcolor: #000000 !important;
            --lwt-accent-color: #000000 !important;
            --lwt-toolbarbutton-icon-fill: #cdd6f4 !important;
          }
          #navigator-toolbox,
          #TabsToolbar,
          #PersonalToolbar,
          #nav-bar {
            background-color: #000000 !important;
          }
          #sidebar-box {
            display: none !important;
          }
        '';

        userContent = ''
          @-moz-document url("about:newtab"), url("about:home"), url("about:blank") {
            body { background-color: #000000 !important; }
          }
        '';
      };
    };
  };
}
