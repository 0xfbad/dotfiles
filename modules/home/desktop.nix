_: {
  flake.homeModules.desktop = {pkgs, ...}: {
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
      gpu-screen-recorder # hardware-accelerated screen recording via NVENC
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
