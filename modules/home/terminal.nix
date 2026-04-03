_: {
  flake.homeModules.terminal = {pkgs, ...}: {
    # broot needs home-manager integration for the br shell function
    programs.broot = {
      enable = true;
      enableZshIntegration = true;
    };

    home.packages = with pkgs; [
      # fonts
      nerd-fonts.jetbrains-mono
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-color-emoji
      liberation_ttf

      # cli utilities
      sox
      fastfetch
      less
      jq
      jnv # modern jq, TUI where you build filters and see results live
      file
      socat
      psmisc
      libqalculate
      numbat # modern calculator, understands units (e.g. 3 meters + 2 feet)
      nix-output-monitor # nh uses this for build progress (tree view, download/build status)
      csvlens # like less but for CSV, aligned columns, filtering, search
      navi # interactive cheatsheet tool, fuzzy search commands with arg placeholders
      # carapace enabled via programs.carapace in zsh module
      wiki-tui # wikipedia in your terminal, fuzzy search, section jumping
      circumflex # hacker news TUI, reader mode extracts article text, threaded comments

      # modern replacements
      sd # modern sed, uses normal regex so no escaping needed
      procs # modern ps, tree view, per-process ports, docker container names
      doggo # modern dig, colored output, DoH/DoT support, JSON mode
      duf # modern df, grouped table by device type, auto-adjusts to terminal
      viddy # modern watch, highlights diffs between runs, scrollable history
      choose # modern cut/awk, human-friendly field selection, negative indexing

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
      fclones # finds duplicate files, hashes progressively to skip full reads
      # broot is enabled via programs.broot above for the br shell function
      trashy # modern rm, moves to FreeDesktop trash so Dolphin can recover files
      ouch # modern tar/zip/gzip, auto-detects format from extension

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
      trippy # modern traceroute, real-time latency graphs per hop
      bandwhich # shows bandwidth usage per process and per connection
      xh # modern httpie, syntax-highlighted responses, sessions
      gping # modern ping, real-time line graph, multiple hosts on same chart
      miniserve # modern python -m http.server, file upload, auth, TLS, QR code

      # multiplexers
      tmux

      # system tools
      libnotify
      hyprmon
      hyprpicker
      hyprsunset
      hyprdim
      wl-clip-persist
      gum
      lazydocker
      lazyjournal # TUI for browsing journalctl, docker logs, and plain log files
      inxi
      playerctl
      brightnessctl
      bluetui
      impala
      pueue # background task queue, survives terminal closes, concurrency control
      process-compose # like docker-compose for bare processes, YAML config, TUI
      tailspin # pipe any log through tspin, auto-highlights dates/IPs/UUIDs/severity
      watchexec # modern entr, file watcher that auto-ignores .git, coalesces events
      wlctl

      # fun
      cowsay
      vhs # records terminal GIFs from scripts, deterministic output
      glow # renders markdown in the terminal with a file browser TUI
      charm-freeze # generates pretty PNG/SVG screenshots of code or terminal output
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
