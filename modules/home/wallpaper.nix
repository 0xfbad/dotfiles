_: {
  flake.modules.homeManager.wallpaper =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      wallpaper = pkgs.writeShellApplication {
        name = "wallpaper";
        runtimeInputs = [
          pkgs.coreutils
          pkgs.findutils
          pkgs.jq
          config.services.awww.package
        ];
        text = ''
          WALL_DIR="$HOME/dotfiles/wallpapers"

          mapfile -t walls < <(find "$WALL_DIR" -type f \( -name '*.jpg' -o -name '*.png' \) | shuf)
          if [ ''${#walls[@]} -eq 0 ]; then
            exit 0
          fi

          out=
          # After=awww.service does not wait for its socket
          for _ in $(seq 50); do
            out=$(awww query --json 2> /dev/null) && break
            sleep 0.2
          done

          mapfile -t mons < <(jq -r '.[][].name' <<< "$out")

          for i in "''${!mons[@]}"; do
            idx=$((i % ''${#walls[@]}))
            awww img -o "''${mons[$i]}" \
              --fill-color 000000 \
              --transition-type grow \
              --transition-pos 0.5,0.5 \
              --transition-duration 1 \
              --transition-fps 60 \
              "''${walls[$idx]}"
          done
        '';
      };
    in
    {
      services.awww.enable = true;

      systemd.user.services.wallpaper = {
        Unit = {
          Description = "Random wallpaper per output";
          ConditionEnvironment = "WAYLAND_DISPLAY";
          Requires = [ "awww.service" ];
          After = [ "awww.service" ];
          PartOf = [ config.wayland.systemd.target ];
        };
        Service = {
          Type = "oneshot";
          ExecStart = lib.getExe wallpaper;
        };
        # no Install, WantedBy cycles through awww.service, the timer starts it
      };

      systemd.user.timers.wallpaper = {
        Unit = {
          Description = "Rotate the wallpaper";
          PartOf = [ config.wayland.systemd.target ];
        };
        Timer = {
          OnActiveSec = "0";
          OnUnitActiveSec = "30m";
        };
        Install.WantedBy = [ config.wayland.systemd.target ];
      };
    };
}
