{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # browsers
    firefox
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

    # productivity
    libreoffice
    odt2txt
    bitwarden-desktop
    obsidian

    # screenshots
    swappy
    font-awesome
    slurp
    imagemagick
    wl-clipboard
    wf-recorder
    pngquant

    # gaming
    prismlauncher
    steam
    lutris
    superTuxKart

    # vpn and networking
    openvpn
    openconnect
    wireguard-tools
    netbird
    netbird-ui
    remmina

    # gnome extensions
    gnomeExtensions.clipboard-indicator
    gnomeExtensions.vitals
    gnomeExtensions.tiling-shell

    # misc
    spotify
  ];
}
