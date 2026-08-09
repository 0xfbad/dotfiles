_: {
  flake.modules.homeManager.terminal =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      # rar decoding lives behind the unfree unrar feature, off in nixpkgs by default
      ouchPkg = pkgs.ouch.override { enableUnfree = true; };

      # one top dir extracts in place, otherwise ouch makes a basename folder to avoid a tarbomb
      ouch-open = pkgs.writeShellApplication {
        name = "ouch-open";
        runtimeInputs = [
          ouchPkg
        ]
        ++ (with pkgs; [
          libnotify
          coreutils
          gawk
        ]);
        text = ''
          archive="''${1:-}"
          if [ -z "$archive" ] || [ ! -f "$archive" ]; then
            notify-send -u critical "ouch-open" "Invalid file: $archive"
            exit 1
          fi

          dir="$(dirname "$archive")"
          base="$(basename "$archive")"
          cd "$dir"

          # --quiet drops the header and prints symlinks without the arrow to their target
          top_count=0
          if listing="$(ouch list --quiet "$archive" 2>/dev/null)"; then
            top_count="$(printf '%s\n' "$listing" \
              | awk -F'/' 'NF>0 && $1!="" {print $1}' \
              | sort -u \
              | wc -l)"
          fi

          err="$(mktemp)"
          trap 'rm -f "$err"' EXIT

          rc=0
          if [ "$top_count" = "1" ]; then
            ouch decompress --yes --here "$archive" 2>"$err" || rc=$?
          else
            ouch decompress --yes "$archive" 2>"$err" || rc=$?
          fi

          if [ "$rc" = "0" ]; then
            notify-send "Extracted" "$base"
          else
            notify-send -u critical "Extraction failed" "$(tail -c 500 "$err")"
          fi
        '';
      };

      # JQ_COLORS takes sgr sequences, not hex
      sgr =
        hex:
        let
          ch = n: toString (lib.fromHexString (builtins.substring n 2 hex));
        in
        "38;2;${ch 1};${ch 3};${ch 5}";

      archiveMimeTypes = [
        "application/zip"
        "application/x-zip-compressed"
        "application/x-tar"
        "application/x-compressed-tar"
        "application/x-bzip2-compressed-tar"
        "application/x-bzip-compressed-tar"
        "application/x-bzip3-compressed-tar"
        "application/x-xz-compressed-tar"
        "application/x-zstd-compressed-tar"
        "application/x-lzma-compressed-tar"
        "application/x-lzip-compressed-tar"
        "application/x-lz4-compressed-tar"
        "application/gzip"
        "application/x-gzip"
        "application/x-bzip"
        "application/x-bzip2"
        "application/x-bzip3"
        "application/x-xz"
        "application/x-lzma"
        "application/x-lzip"
        "application/zstd"
        "application/x-lz4"
        "application/x-7z-compressed"
        "application/vnd.rar"
        "application/x-rar"
        "application/x-rar-compressed"
      ];
    in
    {
      # broot needs home-manager integration for the br shell function
      programs.broot.enable = true;

      programs.fastfetch = {
        enable = true;
        settings = {
          logo.padding.top = 1;
          display.color = {
            keys = config.colors.accent;
            title = config.colors.accent;
          };
          # any user config replaces the builtin module list outright, omitting this renders only the logo
          modules = [
            "title"
            "separator"
            "os"
            "host"
            "kernel"
            "uptime"
            "packages"
            "shell"
            "display"
            "de"
            "wm"
            "terminal"
            "terminalfont"
            "cpu"
            "gpu"
            "memory"
            "swap"
            "disk"
            "localip"
            "battery"
            "poweradapter"
            "locale"
            "break"
            "colors"
          ];
        };
      };

      programs.navi.enable = true;

      programs.numbat = {
        enable = true;
        settings = {
          intro-banner = "off";
          # otherwise numbat hits the network for currency rates on every start
          exchange-rates.fetching-policy = "on-first-use";
        };
      };

      programs.lazydocker = {
        enable = true;
        settings = {
          # lazydocker still shells out to docker-compose without this
          commandTemplates.dockerCompose = "docker compose";
          gui = {
            returnImmediately = true;
            theme.activeBorderColor = [
              "magenta"
              "bold"
            ];
          };
        };
      };

      programs.ripgrep = {
        enable = true;
        arguments = [
          "--smart-case"
          "--hidden"
          "--glob=!.git/*"
          "--max-columns=150"
          "--max-columns-preview"
        ];
      };

      # hidden only reaches the interactive alias, ignores is the global half
      programs.fd = {
        enable = true;
        hidden = true;
        ignores = [
          ".git/"
          "node_modules/"
          "result"
        ];
      };

      programs.less = {
        enable = true;
        options = {
          RAW-CONTROL-CHARS = true;
          mouse = true;
          quit-if-one-screen = true;
        };
      };

      programs.jq = {
        enable = true;
        colors = {
          null = sgr config.colors.surface1;
          false = sgr config.colors.red;
          true = sgr config.colors.green;
          numbers = sgr config.colors.peach;
          strings = sgr config.colors.yellow;
          arrays = sgr config.colors.accent;
          objects = sgr config.colors.text;
          objectKeys = sgr config.colors.blue;
        };
      };

      programs.imv.enable = true;

      programs.zathura = {
        enable = true;
        options = {
          selection-clipboard = "clipboard";
          guioptions = "";
        };
      };

      home.packages = [
        ouch-open
        ouchPkg # modern tar/zip/gzip/bzip2/rar/7z, replaces individual compression tools
      ]
      ++ (with pkgs; [
        # cli utilities
        jnv # modern jq, tui where you build filters and see results live
        file # identifies file types by content, not extension
        socat # bidirectional data relay between streams, sockets, files
        psmisc # killall, fuser, pstree
        libqalculate # calculator with unit conversion and symbolic math
        nix-output-monitor # nh uses this for build progress
        csvlens # like less but for csv, aligned columns, filtering, search
        wiki-tui # wikipedia in your terminal, fuzzy search, section jumping
        circumflex # hacker news tui, reader mode extracts article text, threaded comments

        # modern replacements
        sd # modern sed, uses normal regex so no escaping needed
        procs # modern ps, tree view, ports per process, docker container names
        q # modern dig, doh/dot/doq support, json and table output
        duf # modern df, grouped table by device type, fits the terminal
        viddy # modern watch, highlights diffs between runs, scrollable history
        choose # modern cut/awk, simple field selection, negative indexing

        # file tools
        mdcat # renders markdown in terminal with images and links
        pdfgrep # grep through pdf files
        poppler-utils # pdftotext, pdfinfo, pdfunite, pdftoppm
        resvg # svg renderer, converts svg to png
        magic-wormhole # send files between computers with a single use code
        rsync # incremental transfers that keep layout, the sff function needs it
        ripdrag # drag and drop files from terminal to gui apps
        dua # modern du, interactive tui, fast parallel scanning
        fclones # finds duplicate files, hashes progressively to skip full reads
        rip2 # modern rm, moves to graveyard with undo support

        # networking
        dnsutils # dig, nslookup, nsupdate
        mtr # traceroute and ping combined, runs continuously
        rdap # modern whois, structured queries via the rdap protocol
        lsof # lists open files, finds what uses a port
        sshfs # mount remote directories over ssh as local folders
        trippy # modern traceroute, live latency graphs per hop
        bandwhich # shows bandwidth usage per process and per connection
        xh # modern httpie, highlighted responses, sessions
        gping # modern ping, live line graph, multiple hosts on same chart
        miniserve # modern python -m http.server, file upload, auth, tls, qr code

        # system tools
        libnotify # notify-send for desktop notifications
        gum # charm shell scripting toolkit, interactive prompts and spinners
        lazyjournal # tui for browsing journalctl, docker logs, and plain log files
        playerctl # mpris media player control, play pause next
        brightnessctl # screen brightness control
        bluetui # bluetooth tui manager
        process-compose # like docker-compose for bare processes, yaml config, tui
        tailspin # pipe any log through tspin, highlights dates/ips/uuids/severity
        watchexec # modern entr, file watcher that ignores .git, coalesces events
        wlctl # networkmanager tui for wifi/ethernet/vpn, waybar network click target

        # fun
        cowsay # ascii art cow says your message
        glow # renders markdown in the terminal with a file browser tui
        charm-freeze # generates pretty png or svg screenshots of code or terminal output
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
        categories = [
          "Utility"
          "Archiving"
        ];
        noDisplay = true;
      };

      xdg.mimeApps = {
        enable = true;
        defaultApplications = {
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
          "image/avif" = "imv.desktop";
          "image/heif" = "imv.desktop";
          "image/jxl" = "imv.desktop";
          "application/pdf" = "org.pwmt.zathura.desktop";
          "text/plain" = "Helix.desktop";
          "text/markdown" = "Helix.desktop";
          "text/x-markdown" = "Helix.desktop";
        }
        // (builtins.listToAttrs (
          map (m: {
            name = m;
            value = "ouch-open.desktop";
          }) archiveMimeTypes
        ));
      };
    };
}
