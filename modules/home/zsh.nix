_: {
  flake.homeModules.zsh = _: {
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
        open = "xdg-open";
        rebuild = "nix flake check ~/dotfiles && nh os switch";
        update = "nix flake check ~/dotfiles && nh os switch -u";
        gc = "NH_NOM=0 nh clean all --keep 3 --keep-since 7d";
        cc = "claude --dangerously-skip-permissions";
        qalc = "qalc -s 'autocalc' -s 'decimal comma off'";
      };
      oh-my-zsh = {
        enable = true;
        plugins = [];
      };
      initContent = ''
        zstyle ':completion:*' menu select
        zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
        setopt menu_complete

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
  };
}
