_: {
  flake.homeModules.desktop = {pkgs, ...}: {
    # disable remmina tray icon autostart
    xdg.configFile."autostart/remmina-applet.desktop".text = ''
      [Desktop Entry]
      Type=Application
      Name=Remmina Applet
      Exec=remmina -i
      Hidden=true
    '';

    home.packages = with pkgs; [
      # browsers
      ungoogled-chromium
      tor
      torsocks

      # media
      obs-studio
      vlc
      mpv
      yt-dlp
      ffmpeg
      gimp3-with-plugins
      gimp3Plugins.gmic

      # communication
      signal-desktop
      vesktop
      zoom-us
      weechat

      # productivity
      libreoffice
      odt2txt
      obsidian

      # video editing
      kdePackages.kdenlive

      # pdf annotation
      xournalpp

      # screenshots and recording
      satty
      font-awesome
      grimblast # grim+slurp wrapper, --freeze for screen freeze, active/area/output modes
      imagemagick
      wl-clipboard
      wl-screenrec # hardware-accelerated screen recording via DMA-BUF
      pngquant

      # clipboard
      cliphist # clipboard history, stores text and images, pipe through walker

      # wallpaper
      swww # animated wallpaper transitions (fade, wipe, grow)

      # hyprland tools
      pyprland # scratchpads, expose mode, lost window recovery

      # gaming
      bottles
      prismlauncher
      supertuxkart

      # audio mixers
      pavucontrol
      pwvucontrol

      # vpn and networking
      openvpn
      openconnect
      wireguard-tools
      netbird
      netbird-ui
      remmina

      # matlab
      matlab

      # misc
      spotify
    ];
  };
}
