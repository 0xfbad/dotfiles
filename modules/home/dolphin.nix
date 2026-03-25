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

    xdg.mimeApps.defaultApplications = {
      "inode/directory" = "org.kde.dolphin.desktop";
    };
  };
}
