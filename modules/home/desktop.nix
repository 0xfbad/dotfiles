_: {
  flake.homeModules.desktop = {pkgs, ...}: {
    home.packages = with pkgs; [
      # browsers
      ungoogled-chromium # chromium with google services stripped out
      torsocks # route any app's traffic through tor

      # media
      obs-studio # screen recording and streaming
      vlc # video player, plays everything
      mpv # lightweight video player, scriptable
      yt-dlp # download videos from youtube and 1000+ sites
      ffmpeg # video/audio conversion, encoding, streaming
      gimp3-with-plugins # image editor
      gimp3Plugins.gmic # advanced image processing filters for GIMP

      # communication
      signal-desktop # encrypted messaging
      vesktop # discord client with screen sharing on Wayland
      zoom-us # video conferencing
      weechat # IRC client, extensible, runs in terminal

      # productivity
      libreoffice # office suite (docs, sheets, presentations)
      odt2txt # converts OpenDocument files to plain text
      # video editing
      kdePackages.kdenlive # video editor

      # pdf annotation
      xournalpp # PDF annotation and handwriting

      # screenshots and recording
      satty # screenshot annotation tool for Wayland
      font-awesome # icon font used by status bars and widgets
      imagemagick # image manipulation from CLI
      wl-clipboard # copy/paste on Wayland (wl-copy, wl-paste)
      wf-recorder # screen recording via wlroots screencopy
      pngquant # lossy PNG compression

      # clipboard
      cliphist # clipboard history, stores text and images

      # wallpaper
      awww # animated wallpaper transitions (fade, wipe, grow)

      # hyprland tools
      pyprland # scratchpads, expose mode, lost window recovery

      # gaming
      bottles # run windows apps and games via Wine
      prismlauncher # open-source minecraft launcher
      supertuxkart # open-source kart racing game

      # vpn and networking
      openconnect # Cisco/Juniper VPN client
      wireguard-tools # WireGuard VPN utilities
      netbird # peer-to-peer VPN mesh
      netbird-ui # GUI for netbird
      remmina # remote desktop client (RDP, VNC, SSH)

      # matlab
      matlab # numerical computing environment

      # email and passwords
      thunderbird # email client
      keepassxc # offline password manager

      # misc
      spotify # music streaming
    ];
  };
}
