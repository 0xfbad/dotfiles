_: {
  flake.homeModules.terminal = {pkgs, ...}: let
    # smart archive opener: extracts in place if archive wraps contents in a
    # single top-level dir, otherwise creates a subfolder named after the archive
    ouch-open = pkgs.writeShellApplication {
      name = "ouch-open";
      runtimeInputs = with pkgs; [ouch libnotify coreutils gawk];
      text = ''
        archive="''${1:-}"
        if [ -z "$archive" ] || [ ! -f "$archive" ]; then
          notify-send -u critical "ouch-open" "Invalid file: $archive"
          exit 1
        fi

        dir="$(dirname "$archive")"
        base="$(basename "$archive")"
        cd "$dir"

        # count unique top-level path segments in the archive listing
        top_count=0
        if listing="$(ouch list "$archive" 2>/dev/null)"; then
          top_count="$(printf '%s\n' "$listing" \
            | tail -n +2 \
            | awk -F'/' 'NF>0 && $1!="" {print $1}' \
            | sort -u \
            | wc -l)"
        fi

        err="$(mktemp)"
        trap 'rm -f "$err"' EXIT

        rc=0
        if [ "$top_count" = "1" ]; then
          target="$base"
          ouch decompress --yes "$archive" 2>"$err" || rc=$?
        else
          # strip compound extensions like .tar.gz, fall back to single extension
          case "$base" in
            *.tar.gz|*.tar.bz2|*.tar.bz3|*.tar.xz|*.tar.zst|*.tar.lz4|*.tar.sz|*.tar.br)
              name="''${base%.tar.*}"
              ;;
            *)
              name="''${base%.*}"
              ;;
          esac
          target="$base -> $name/"
          ouch decompress --yes --dir "$name" "$archive" 2>"$err" || rc=$?
        fi

        if [ "$rc" = "0" ]; then
          notify-send "Extracted" "$target"
        else
          notify-send -u critical "Extraction failed" "$(tail -c 500 "$err")"
        fi
      '';
    };

    archiveMimeTypes = [
      "application/zip"
      "application/x-zip-compressed"
      "application/x-tar"
      "application/x-compressed-tar"
      "application/x-bzip-compressed-tar"
      "application/x-xz-compressed-tar"
      "application/x-zstd-compressed-tar"
      "application/x-lzma-compressed-tar"
      "application/gzip"
      "application/x-gzip"
      "application/x-bzip"
      "application/x-bzip2"
      "application/x-xz"
      "application/x-lzma"
      "application/zstd"
      "application/x-zstd"
      "application/x-lz4"
      "application/x-7z-compressed"
      "application/vnd.rar"
      "application/x-rar"
      "application/x-rar-compressed"
      "application/x-snappy-framed"
    ];
  in {
    # broot needs home-manager integration for the br shell function
    programs.broot = {
      enable = true;
      enableZshIntegration = true;
    };

    home.packages =
      [ouch-open]
      ++ (with pkgs; [
        # fonts
        nerd-fonts.jetbrains-mono # monospace font with ligatures and nerd font icons
        material-symbols # google's variable icon font
        noto-fonts # google's unicode coverage font family
        noto-fonts-cjk-sans # chinese, japanese, korean characters
        noto-fonts-color-emoji # google's color emoji set
        liberation_ttf # metric-compatible replacements for arial, times, courier

        # cli utilities
        fastfetch # system info display, faster neofetch
        less # pager
        jq # JSON processor
        jnv # modern jq, TUI where you build filters and see results live
        file # identifies file types by content, not extension
        socat # bidirectional data relay between streams, sockets, files
        psmisc # killall, fuser, pstree
        libqalculate # calculator with unit conversion and symbolic math
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
        q # modern dig, DoH/DoT/DoQ support, JSON and table output
        duf # modern df, grouped table by device type, auto-adjusts to terminal
        viddy # modern watch, highlights diffs between runs, scrollable history
        choose # modern cut/awk, human-friendly field selection, negative indexing

        # file tools
        mdcat # renders markdown in terminal with images and links
        fd # modern find, simpler syntax, respects .gitignore
        ripgrep # modern grep, fast, respects .gitignore
        fzf # fuzzy finder for files, history, anything piped in
        pdfgrep # grep through PDF files
        poppler # PDF tools (pdftotext, pdfinfo, pdfunite)
        resvg # SVG renderer, converts SVG to PNG
        magic-wormhole # send files between computers with a one-time code
        ripdrag # drag and drop files from terminal to GUI apps
        dua # modern du, interactive TUI, fast parallel scanning
        imv # lightweight Wayland image viewer
        zathura # lightweight PDF viewer, vim keybinds
        fclones # finds duplicate files, hashes progressively to skip full reads
        # broot is enabled via programs.broot above for the br shell function
        rip2 # modern rm, moves to graveyard with undo support
        ouch # modern tar/zip/gzip/bzip2/rar/7z, replaces individual compression tools

        # networking
        dnsutils # dig, nslookup, nsupdate
        mtr # traceroute + ping combined, runs continuously
        rdap # modern whois, structured queries via RDAP protocol
        lsof # lists open files, useful for finding what's using a port
        sshfs # mount remote directories over SSH as local folders
        trippy # modern traceroute, real-time latency graphs per hop
        bandwhich # shows bandwidth usage per process and per connection
        xh # modern httpie, syntax-highlighted responses, sessions
        gping # modern ping, real-time line graph, multiple hosts on same chart
        miniserve # modern python -m http.server, file upload, auth, TLS, QR code

        # system tools
        libnotify # notify-send for desktop notifications
        hyprmon # hyprland monitor management
        hyprpicker # screen color picker for hyprland
        hyprsunset # blue light filter for hyprland
        hyprdim # dims inactive windows in hyprland
        wl-clip-persist # keeps clipboard alive after source app closes on Wayland
        gum # charm's shell scripting toolkit, interactive prompts and spinners
        lazydocker # TUI for docker containers, images, volumes, logs
        lazyjournal # TUI for browsing journalctl, docker logs, and plain log files
        playerctl # MPRIS media player control (play, pause, next)
        brightnessctl # screen brightness control
        bluetui # bluetooth TUI manager
        process-compose # like docker-compose for bare processes, YAML config, TUI
        tailspin # pipe any log through tspin, auto-highlights dates/IPs/UUIDs/severity
        watchexec # modern entr, file watcher that auto-ignores .git, coalesces events
        wlctl # wayland output control (resolution, position, transform)

        # fun
        cowsay # ASCII art cow says your message
        glow # renders markdown in the terminal with a file browser TUI
        charm-freeze # generates pretty PNG/SVG screenshots of code or terminal output
      ]);

    # hidden handler entry so dolphin can route archive clicks to ouch
    xdg.desktopEntries.ouch-open = {
      name = "Ouch (Extract)";
      genericName = "Archive Extractor";
      comment = "Decompress archive with ouch";
      exec = "${ouch-open}/bin/ouch-open %f";
      icon = "package-x-generic";
      terminal = false;
      mimeType = archiveMimeTypes;
      categories = ["Utility" "Archiving"];
      noDisplay = true;
    };

    xdg.mimeApps = {
      enable = true;
      defaultApplications =
        {
          "x-scheme-handler/terminal" = "org.wezfurlong.wezterm.desktop";
          "x-scheme-handler/http" = "firefox.desktop";
          "x-scheme-handler/https" = "firefox.desktop";
          "text/html" = "firefox.desktop";
          "application/xhtml+xml" = "firefox.desktop";
          "image/png" = "imv.desktop";
          "image/jpeg" = "imv.desktop";
          "image/gif" = "imv.desktop";
          "image/webp" = "imv.desktop";
          "image/bmp" = "imv.desktop";
          "image/tiff" = "imv.desktop";
          "image/svg+xml" = "imv.desktop";
          "application/pdf" = "org.pwmt.zathura.desktop";
          "text/plain" = "Helix.desktop";
          "text/markdown" = "Helix.desktop";
          "text/x-markdown" = "Helix.desktop";
        }
        // (builtins.listToAttrs (map (m: {
            name = m;
            value = "ouch-open.desktop";
          })
          archiveMimeTypes));
    };
  };
}
