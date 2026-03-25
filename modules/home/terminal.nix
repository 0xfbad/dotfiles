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
      defaultApplications = let
        zed = "dev.zed.Zed.desktop";
      in {
        "x-scheme-handler/terminal" = "org.wezfurlong.wezterm.desktop";
        "x-scheme-handler/http" = "firefox.desktop";
        "x-scheme-handler/https" = "firefox.desktop";
        "text/html" = "firefox.desktop";
        "application/xhtml+xml" = "firefox.desktop";

        # open text/code files in zed
        "text/plain" = zed;
        "application/json" = zed;
        "application/xml" = zed;
        "application/yaml" = zed;
        "application/toml" = zed;
        "application/x-shellscript" = zed;
        "text/x-python" = zed;
        "text/x-rust" = zed;
        "text/x-go" = zed;
        "text/x-c" = zed;
        "text/x-c++" = zed;
        "text/x-java" = zed;
        "text/x-script.python" = zed;
        "text/x-markdown" = zed;
        "text/markdown" = zed;
        "text/csv" = zed;
        "text/css" = zed;
        "text/javascript" = zed;
        "application/javascript" = zed;
        "application/x-nix" = zed;
      };
    };
  };
}
