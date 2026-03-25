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

      # screenshots and recording
      swappy
      font-awesome
      slurp
      imagemagick
      wl-clipboard
      wf-recorder
      pngquant

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
