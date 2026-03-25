_: {
  flake.homeModules.terminal = {pkgs, ...}: {
    home.packages = with pkgs; [
      # fonts
      nerd-fonts.jetbrains-mono

      # cli utilities
      cloc
      sox
      fastfetch
      less

      jq
      file
      socat
      psmisc
      libqalculate

      # file tools
      mdcat
      fd
      ripgrep
      fzf
      pdfgrep
      poppler
      resvg
      magic-wormhole
      ripdrag
      dust
      imv

      # compression
      zip
      unzip
      unp
      bzip2
      gzip
      rar
      gnutar
      p7zip

      # networking
      dnsutils
      mtr
      whois
      lsof
      traceroute
      sshfs

      # multiplexers
      tmux

      # fun
      cowsay
    ];

    xdg.mimeApps = {
      enable = true;
      defaultApplications = {
        "x-scheme-handler/terminal" = "org.wezfurlong.wezterm.desktop";
        "x-scheme-handler/http" = "firefox.desktop";
        "x-scheme-handler/https" = "firefox.desktop";
        "text/html" = "firefox.desktop";
        "application/xhtml+xml" = "firefox.desktop";
      };
    };
  };
}
