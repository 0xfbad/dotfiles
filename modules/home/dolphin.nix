_: {
  flake.homeModules.dolphin = {pkgs, ...}: {
    home.packages = with pkgs.kdePackages; [
      dolphin
      dolphin-plugins
      qtsvg
      qtwayland
      kio
      kio-fuse
      kio-extras
      kio-admin
      baloo
      baloo-widgets
      kdegraphics-thumbnailers
      ffmpegthumbs
      qtimageformats
      kimageformats
      breeze-icons
    ];

    xdg.configFile."dolphinrc".text = ''
      [General]
      GlobalViewProps=true
      ShowFullPath=true
      ShowZoomSlider=false
      ShowStatusBar=1
    '';

    xdg.dataFile."dolphin/view_properties/global/.directory".text = ''
      [Dolphin]
      SortFoldersFirst=false
      SortHiddenLast=false
      SortOrder=1
      SortRole=modificationtime
      Version=4
      ViewMode=0
    '';

    xdg.mimeApps.defaultApplications = {
      "inode/directory" = "org.kde.dolphin.desktop";
    };
  };
}
