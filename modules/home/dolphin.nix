{ inputs, ... }: {
  flake.modules.homeManager.dolphin =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      home = config.home.homeDirectory;
    in
    {
      imports = [
        inputs.plasma-manager.homeModules.plasma-manager
      ];

      # these plugins load only because qt.enable in gtk.nix puts this profile on QT_PLUGIN_PATH
      home.packages = with pkgs.kdePackages; [
        dolphin
        dolphin-plugins
        qtsvg
        qtwayland
        kio
        kio-fuse
        kio-extras
        kio-admin
        kdegraphics-thumbnailers
        ffmpegthumbs
        qtimageformats
        kimageformats
        breeze-icons
        filelight
        baloo
        baloo-widgets
      ];

      # plasma-manager opens these for writing, the old generation left them as store symlinks
      home.activation.unlinkKdeStoreSymlinks = lib.hm.dag.entryBefore [ "configure-plasma" ] ''
        for f in \
          "${config.xdg.configHome}/kdeglobals" \
          "${config.xdg.configHome}/dolphinrc" \
          "${config.xdg.configHome}/baloofilerc" \
          "${config.xdg.dataHome}/dolphin/view_properties/global/.directory"; do
          case "$(readlink "$f")" in
            /nix/store/*) run rm -f $VERBOSE_ARG "$f" ;;
          esac
        done
      '';

      programs.plasma = {
        enable = true;

        configFile = {
          dolphinrc.General = {
            Version = 202;
            ShowFullPath = true;
            ShowStatusBar = "FullWidth";
            ShowSelectionToggle = false;
            DoubleClickViewAction = "go_up";
          };

          baloofilerc = {
            "Basic Settings"."Indexing-Enabled" = true;
            General = {
              # ~/git and the windows image are 88G of churn that rg and filelight already cover
              "exclude folders" = lib.concatStringsSep "," [
                "${home}/git"
                "${home}/winboat"
              ];
              "index hidden folders" = false;
            };
          };
        };

        dataFile."dolphin/view_properties/global/.directory".Dolphin = {
          SortFoldersFirst = false;
          SortOrder = 1;
          SortRole = "modificationtime";
          Version = 4;
        };
      };

      # the shipped unit is off the user search path and its ExecCondition wants plasma-workspace
      systemd.user.services.kde-baloo = {
        Unit = {
          Description = "Baloo File Indexer Daemon";
          After = [ "graphical-session.target" ];
          PartOf = [ "graphical-session.target" ];
        };
        Service = {
          ExecStart = "${pkgs.kdePackages.baloo}/libexec/kf6/baloo_file";
          Slice = "background.slice";
          CPUWeight = 1;
          IOWeight = 1;
          MemoryHigh = "25%";
        };
        Install.WantedBy = [ "graphical-session.target" ];
      };

      xdg.mimeApps.defaultApplications = {
        "inode/directory" = "org.kde.dolphin.desktop";
      };
    };
}
