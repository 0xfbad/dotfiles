_: {
  flake.modules.homeManager.zsh =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      programs = {
        carapace = {
          enable = true;
          ignoreCase = true;
        };

        # LS_COLORS for eza and the completion list
        vivid = {
          enable = true;
          activeTheme = lib.mkDefault "catppuccin-mocha";
        };

        zsh = {
          enable = true;
          enableCompletion = true;
          # the hm default flips to this at stateVersion 26.05, pinned now to move the files once
          dotDir = "${config.xdg.configHome}/zsh";

          # carapace has no hm option for the bridges, only these two shells exist here
          sessionVariables.CARAPACE_BRIDGES = "zsh,bash";

          autosuggestion = {
            enable = true;
            strategy = [
              "history"
              "completion"
            ];
            highlight = "fg=${config.colors.overlay0}";
          };

          syntaxHighlighting = {
            enable = true;
            # hm appends main on its own, mkForce keeps the array exactly as written
            highlighters = lib.mkForce [
              "main"
              "cursor"
            ];
          };

          # atuin owns plain up arrow, substring search takes ctrl-up and ctrl-down
          historySubstringSearch = {
            enable = true;
            searchUpKey = [ "^[[1;5A" ];
            searchDownKey = [ "^[[1;5B" ];
          };

          # atuin is the only store, save 0 stops the file write, size still feeds autosuggestion
          history = {
            size = 10000;
            save = 0;
            share = false;
            ignoreAllDups = true;
            findNoDups = true;
          };

          setOptions = [
            "ALWAYS_TO_END"
            "AUTO_CD"
            "AUTO_PUSHD"
            "COMPLETE_IN_WORD"
            "HIST_REDUCE_BLANKS"
            "HIST_VERIFY"
            "INTERACTIVE_COMMENTS"
            "LONG_LIST_JOBS"
            "MENU_COMPLETE"
            "NO_FLOW_CONTROL"
            "PUSHD_IGNORE_DUPS"
            "PUSHD_SILENT"
          ];

          dirHashes = {
            dots = "$HOME/dotfiles";
            dl = "$HOME/Downloads";
            proj = "$HOME/projects";
          };

          # the only piece of oh-my-zsh worth loading, double esc prefixes sudo
          plugins = [
            {
              name = "sudo";
              src = "${pkgs.oh-my-zsh}/share/oh-my-zsh/plugins/sudo";
              file = "sudo.plugin.zsh";
            }
          ];

          shellAliases = {
            ls = "eza -l";
            la = "eza -la";
            cat = "bat -pp";
            # bat-extras wrappers are not drop ins for grep/diff
            bgrep = "batgrep";
            bdiff = "batdiff";
            open = "xdg-open";
            lint = "nix flake check ~/dotfiles";
            rebuild = "nix flake check ~/dotfiles && nh os switch";
            update = "nix flake update --flake ~/dotfiles && nix flake check ~/dotfiles && nh os switch";
            gc = "nh clean all --keep 3 --keep-since 7d";
            cc = "claude --dangerously-skip-permissions";
            qalc = "qalc -s 'autocalc' -s 'decimal comma off'";
            clip = "wl-copy --trim-newline";
            pwdc = "pwd | wl-copy --trim-newline";
            # copy last command to clipboard
            lcc = "fc -ln -1 | sed 's/^[[:space:]]*//' | wl-copy --trim-newline";
            termbin = "nc termbin.com 9999";
            dupe = "setsid wezterm start --cwd \"$(pwd)\"";
            watch = "viddy";
            "-" = "cd -";
          };

          shellGlobalAliases = {
            "..." = "../..";
            "...." = "../../..";
          };

          siteFunctions = {
            optimize-video = ''
              local input="$1"
              local output="''${input%.*}-optimized.mp4"
              ffmpeg -i "$input" -c:v libx264 -crf 23 -c:a aac -b:a 128k "$output"
            '';

            optimize-image = ''
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
                  print -u2 "unsupported format: $ext"
                  return 1
                  ;;
              esac
            '';

            greet = ''
              local hour=$(date +%H) bucket
              if (( hour >= 5 && hour < 12 )); then bucket=morning
              elif (( hour < 17 )); then bucket=afternoon
              elif (( hour < 22 )); then bucket=evening
              else bucket=night
              fi
              local line="$(jq -r --arg b "$bucket" --arg d "''${(L)$(date +%A)}" \
                '.any + .[$b] + .days[$d] | .[]' ${./zsh-greetings.json} | shuf -n1)"
              print -r -- "''${line//\{name\}/$USER}"
            '';
          };

          initContent = lib.mkMerge [
            # order 200 is the hm zellij slot, exec must replace the shell before the rest parses
            (lib.mkOrder 200 ''
              if [[ -z "$ZELLIJ" && "$TERM" != "linux" && "$TERM" != "dumb" && -z "$SSH_CONNECTION" ]]; then
                # attach -c would mirror the newest live session into every new terminal
                exec zellij
              fi
            '')

            ''
              zstyle ':completion:*' menu select
              zstyle ':completion:*' matcher-list 'm:{[:lower:][:upper:]-_}={[:upper:][:lower:]_-}' 'r:|=*' 'l:|=* r:|=*'
              zstyle -e ':completion:*' list-colors 'reply=(''${(s.:.)LS_COLORS})'
              zstyle ':completion:*' group-name '''
              zstyle ':completion:*' special-dirs true
              zstyle ':completion:*' squeeze-slashes true
              zstyle ':completion:*' use-cache yes
              zstyle ':completion:*' cache-path "$HOME/.cache/zsh"
              zstyle ':completion:*:descriptions' format '%F{yellow}-- %d --%f'
              zstyle ':completion:*:warnings' format '%F{red}no matches%f'
              zstyle ':completion:*:*:*:*:processes' command "ps -u $USER -o pid,user,comm -w -w"
              zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#) ([0-9a-z-]#)*=01;34=0=01'

              # terminal keys zsh leaves unbound, both normal and application mode
              bindkey -e
              bindkey '^[[H' beginning-of-line
              bindkey '^[OH' beginning-of-line
              bindkey '^[[1~' beginning-of-line
              bindkey '^[[F' end-of-line
              bindkey '^[OF' end-of-line
              bindkey '^[[4~' end-of-line
              bindkey '^[[3~' delete-char
              bindkey '^[[5~' up-line-or-history
              bindkey '^[[6~' down-line-or-history
              bindkey '^[[Z' reverse-menu-complete
              bindkey '^[[1;5C' forward-word
              bindkey '^[[1;5D' backward-word
              bindkey '^[[3;5~' kill-word
              bindkey ' ' magic-space

              autoload -U edit-command-line
              zle -N edit-command-line
              bindkey '^X^E' edit-command-line

              _ctrl_z_toggle() {
                if [[ $#BUFFER -eq 0 ]]; then
                  BUFFER="fg"
                  zle accept-line
                else
                  zle push-input
                  zle clear-screen
                fi
              }
              zle -N _ctrl_z_toggle
              bindkey '^Z' _ctrl_z_toggle

              # MANPAGER, so anything shelling out to man gets bat too
              ${pkgs.bat-extras.batman.passthru.shellInit "zsh"}

              # LESSOPEN, so less previews archives, directories and binaries
              ${pkgs.bat-extras.batpipe.passthru.shellInit "zsh"}
            ''

            # after the autoload -Uz that siteFunctions emits at 1000
            (lib.mkOrder 1300 ''
              ZSH_HIGHLIGHT_STYLES[path_pathseparator]='fg=${config.colors.overlay0}'
              ZSH_HIGHLIGHT_STYLES[path_prefix_pathseparator]='fg=${config.colors.overlay0}'
              ZSH_HIGHLIGHT_STYLES[commandseparator]='fg=${config.colors.teal}'
              ZSH_HIGHLIGHT_STYLES[redirection]='fg=${config.colors.teal}'
            '')

            (lib.mkOrder 1400 ''
              autoload -Uz add-zsh-hook
              add-zsh-hook preexec adroll

              greet | cowsay
            '')
          ];
        };
      };
    };
}
