{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # fonts
    nerd-fonts.jetbrains-mono

    # cli utilities
    fastfetch
    less
    bitwarden-cli
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

    # multiplexers
    tmux

    # fun
    cowsay
  ];

  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    enableCompletion = true;
    syntaxHighlighting.enable = true;
    shellAliases = {
      ls = "eza -l";
      la = "eza -la";
      lt = "eza --tree";
      cat = "bat -pp";
      man = "batman";
      diff = "batdiff";
      grep = "batgrep";
      rebuild = "sudo nixos-rebuild switch --flake ~/dotfiles";
      update = "nix flake update --flake ~/dotfiles && sudo nixos-rebuild switch --flake ~/dotfiles";
      ss = ''grim -g "$(slurp)" - | magick - -shave 1x1 - | swappy -f -'';
      se = "wl-paste | swappy -f -";
      sr = ''wf-recorder -g "$(slurp)"'';
      sra = ''wf-recorder -g "$(slurp)" --audio'';
      gc = "sudo nix-collect-garbage -d && nix-collect-garbage -d";
    };
    oh-my-zsh = {
      enable = true;
      plugins = [ ];
    };
    initContent = ''
      optimize-video() {
        local input="$1"
        local output="''${input%.*}-optimized.mp4"
        ffmpeg -i "$input" -c:v libx264 -crf 23 -c:a aac -b:a 128k "$output"
      }

      optimize-image() {
        local input="$1"
        local ext="''${input##*.}"
        case "''${ext:l}" in
          png)
            pngquant --strip --force --output "''${input%.*}-optimized.png" "$input"
            ;;
          jpg|jpeg)
            magick "$input" -strip -quality 85 "''${input%.*}-optimized.jpg"
            ;;
          *)
            echo "unsupported format: $ext"
            return 1
            ;;
        esac
      }

      greet() {
        local hour=$(date +%H)
        local day=$(date +%u)
        local greetings

        if (( hour >= 5 && hour < 12 )); then
          greetings=(
            "good morning, $USER"
            "wakey, wakey, $USER"
            "guten morgen, $USER"
            "rise and shine, $USER"
            "morning, $USER"
            "top of the morning to you, $USER"
            "have a great day, $USER"
            "look alive, $USER"
            "$USER returns!"
            "back at it, $USER"
            "welcome, $USER"
            "hey there, $USER"
            "hi $USER, how are you?"
            "how's it going, $USER?"
            "what's new, $USER?"
          )
        elif (( hour >= 12 && hour < 17 )); then
          greetings=(
            "hiya, $USER"
            "hi, $USER"
            "guten tag, $USER"
            "good afternoon, $USER"
            "howdy, $USER"
            "buenos dias, $USER"
            "g'day, $USER"
            "hello there, $USER"
            "$USER returns!"
            "back at it, $USER"
            "welcome, $USER"
            "hey there, $USER"
            "hi $USER, how are you?"
            "how's it going, $USER?"
            "what's new, $USER?"
          )
        elif (( hour >= 17 && hour < 22 )); then
          greetings=(
            "good evening, $USER"
            "evening, $USER"
            "nice to see you, $USER"
            "hellooooo, $USER"
            "enjoy the rest of your evening, $USER"
            "fancy seeing you here, $USER"
            "hi there, $USER"
            "$USER returns!"
            "back at it, $USER"
            "welcome, $USER"
            "hey there, $USER"
            "how was your day, $USER?"
            "how's it going, $USER?"
            "winding down, $USER?"
            "evening vibes, $USER"
          )
        else
          greetings=(
            "$USER, you night owl"
            "hey $USER, it's late. time to rest"
            "burning the midnight oil, $USER?"
            "late night coding session, $USER?"
            "$USER, the terminal never sleeps"
            "can't sleep, $USER?"
            "shh, everyone else is asleep, $USER"
            "just you and the machines, $USER"
            "night shift, $USER?"
            "welcome to the graveyard shift, $USER"
            "$USER, the code flows better at night"
            "fancy seeing you here, $USER"
            "hey $USER, sleep is for the weak"
            "another late one, $USER?"
            "midnight hacking, $USER?"
            "$USER after dark"
            "the witching hour, $USER"
            "hey $USER, the bugs come out at night"
          )
        fi

        case $day in
          1) greetings+=("happy monday, $USER") ;;
          2) greetings+=("happy tuesday, $USER") ;;
          3) greetings+=("happy wednesday, $USER") ;;
          4) greetings+=("happy thursday, $USER") ;;
          5) greetings+=("that friday feeling, $USER" "happy friday, $USER") ;;
          6) greetings+=("happy saturday, $USER" "welcome to the weekend, $USER") ;;
          7) greetings+=("happy sunday, $USER" "sunday session, $USER?") ;;
        esac

        local idx=$((RANDOM % ''${#greetings[@]} + 1))
        echo "''${greetings[$idx]}"
      }

      greet | cowsay

      if [[ -z "$ZELLIJ" && "$TERM" != "linux" && -z "$SSH_CONNECTION" ]]; then
        exec zellij
      fi
    '';
  };

  programs.eza = {
    enable = true;
    enableZshIntegration = true;
    icons = "auto";
  };

  xdg.configFile."eza/theme.yml".source =
    let
      eza-themes = pkgs.fetchFromGitHub {
        owner = "eza-community";
        repo = "eza-themes";
        rev = "c03051f67e84110fbae91ab7cbc377b3460f035c";
        hash = "sha256-qEC7H9/ghnjkwmMZ788TSgS9ysyIfD+3NHCjxq0Dps0=";
      };
    in
    "${eza-themes}/themes/catppuccin.yml";

  programs.atuin = {
    enable = true;
    enableZshIntegration = true;
    settings = {
      auto_sync = false;
      update_check = false;
      enter_accept = true;
    };
  };

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
    options = [
      "--cmd"
      "cd"
    ];
  };

  programs.btop = {
    enable = true;
    settings.color_theme = "catppuccin_mocha";
  };

  programs.starship = {
    enable = true;
    enableZshIntegration = true;
    settings = {
      character = {
        success_symbol = "[\\$](bold green)";
        error_symbol = "[\\$](bold red)";
      };
    };
  };

  programs.tealdeer = {
    enable = true;
    settings.updates.auto_update = true;
  };

  programs.bat = {
    enable = true;
    config.theme = "Catppuccin Mocha";
    extraPackages = with pkgs.bat-extras; [
      batman
      batdiff
      batgrep
    ];
  };

  programs.zellij = {
    enable = true;
    settings = {
      theme = "catppuccin-mocha";
      default_layout = "compact";
      show_startup_tips = false;
    };
  };

  programs.yazi =
    let
      yazi-flavors = pkgs.fetchFromGitHub {
        owner = "yazi-rs";
        repo = "flavors";
        rev = "ffe6e3a16c5c51d7e2dedacf8de662fe2413f73a";
        hash = "sha256-hEnrvfJwCAgM12QwPmjHEwF5xNrwqZH1fTIb/QG0NFI=";
      };
    in
    {
      enable = true;
      enableZshIntegration = true;
      flavors.catppuccin-mocha = "${yazi-flavors}/catppuccin-mocha.yazi";
      settings.flavor.use = "catppuccin-mocha";
    };

  programs.gitui =
    let
      catppuccin-gitui = pkgs.fetchFromGitHub {
        owner = "catppuccin";
        repo = "gitui";
        rev = "df2f59f847e047ff119a105afff49238311b2d36";
        hash = "sha256-DRK/j3899qJW4qP1HKzgEtefz/tTJtwPkKtoIzuoTj0=";
      };
    in
    {
      enable = true;
      theme = builtins.readFile "${catppuccin-gitui}/themes/catppuccin-mocha.ron";
    };

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

  programs.wezterm = {
    enable = true;
    extraConfig = ''
      local wezterm = require("wezterm")
      local seen = {}
      wezterm.on("window-focus-changed", function(window, pane)
        local wid = window:window_id()
        if not seen[wid] then
          seen[wid] = true
          window:maximize()
        end
      end)
      return {
        color_scheme = "Catppuccin Mocha",
        colors = {
          background = "#000000",
        },
        font = wezterm.font("JetBrainsMono Nerd Font"),
        font_size = 11,
        enable_wayland = true,
        enable_tab_bar = false,
        disable_default_key_bindings = true,
        keys = {
          {
            key = "c",
            mods = "CTRL|SHIFT",
            action = wezterm.action_callback(function(window, pane)
              local sel = window:get_selection_text_for_pane(pane)
              if sel and sel ~= "" then
                window:perform_action(wezterm.action.CopyTo("Clipboard"), pane)
              end
            end)
          },
          { key = "v", mods = "CTRL|SHIFT", action = wezterm.action.PasteFrom("Clipboard") },
        },
        window_padding = {
          left = 0,
          right = 0,
          top = 0,
          bottom = 0,
        },
      }
    '';
  };
}
