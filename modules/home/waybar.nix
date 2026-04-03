_: {
  flake.homeModules.waybar = {
    config,
    pkgs,
    ...
  }: let
    c = config.colors;

    pomodoroScript = pkgs.writeShellScript "pomodoro" ''
      STATE="/tmp/pomodoro"
      LOG="$HOME/.local/share/pomodoro.log"
      mkdir -p "$(dirname "$LOG")"

      today=$(date '+%Y-%m-%d')

      case "$1" in
        start)
          # show recent tasks as selectable items, deduped, newest first
          recent=""
          if [ -f "$LOG" ]; then
            recent=$(command grep -v 'cancelled' "$LOG" | sed 's/^[^ ]* [^ ]* - //' | tac | awk '!seen[$0]++' | head -15)
          fi
          task=$(printf "%s" "$recent" | ${pkgs.walker}/bin/walker --dmenu --placeholder "what are you working on?")
          [ -z "$task" ] && exit 0
          echo "$(date +%s) $(( $(date +%s) + 1500 )) $task" > "$STATE"
          echo "$(date '+%Y-%m-%d %H:%M') - $task" >> "$LOG"
          ;;
        stop)
          if [ -f "$STATE" ]; then
            read -r start end task < "$STATE"
            elapsed=$(( $(date +%s) - start ))
            elapsed_min=$(( elapsed / 60 ))
            ${pkgs.libnotify}/bin/notify-send "Pomodoro cancelled" "$task ($elapsed_min min)"
            echo "$(date '+%Y-%m-%d %H:%M') - $task (cancelled after ''${elapsed_min}min)" >> "$LOG"
            rm -f "$STATE"
          fi
          ;;
        status)
          if [ ! -f "$STATE" ]; then
            echo '{"text": "󰔟", "tooltip": "click to start pomodoro", "class": "idle"}'
            exit 0
          fi

          read -r start end task < "$STATE"
          now=$(date +%s)

          if [ "$now" -ge "$end" ]; then
            elapsed=$(( end - start ))
            elapsed_min=$(( elapsed / 60 ))
            rm -f "$STATE"
            ${pkgs.libnotify}/bin/notify-send -u critical "Pomodoro done" "$task (''${elapsed_min}min), take a break"
            echo '{"text": "󰔟", "tooltip": "click to start pomodoro", "class": "idle"}'
            exit 0
          fi

          remaining=$(( end - now ))
          min=$(( remaining / 60 ))
          sec=$(( remaining % 60 ))
          printf '{"text": "󰔟 %02d:%02d %s", "tooltip": "%s", "class": "active"}\n' "$min" "$sec" "$task" "$task"
          ;;
      esac
    '';

    caffeineScript = pkgs.writeShellScript "caffeine" ''
      STATE="/tmp/caffeine"
      case "$1" in
        toggle)
          if [ -f "$STATE" ]; then
            kill "$(cat "$STATE")" 2>/dev/null
            rm -f "$STATE"
          else
            ${pkgs.systemd}/bin/systemd-inhibit --what=idle --who=caffeine --why=manual --mode=block sleep infinity &
            echo $! > "$STATE"
          fi
          ;;
        status)
          if [ -f "$STATE" ] && kill -0 "$(cat "$STATE")" 2>/dev/null; then
            echo '{"text": "󰅶", "tooltip": "caffeine on, click to disable", "class": "active"}'
          else
            rm -f "$STATE" 2>/dev/null
            echo '{"text": "󰛊", "tooltip": "caffeine off, click to enable", "class": "idle"}'
          fi
          ;;
      esac
    '';

    weatherScript = pkgs.writeShellScript "weather" ''
      CACHE="/tmp/waybar-weather"
      CACHE_SCRIPT="/tmp/waybar-weather-script"
      MAX_AGE=900

      # invalidate cache when the script changes (e.g. after a rebuild)
      SELF="$(readlink -f "$0")"
      if [ -f "$CACHE_SCRIPT" ] && [ "$(cat "$CACHE_SCRIPT")" != "$SELF" ]; then
        rm -f "$CACHE"
      fi
      echo "$SELF" > "$CACHE_SCRIPT"

      if [ -f "$CACHE" ]; then
        age=$(( $(date +%s) - $(stat -c %Y "$CACHE") ))
        if [ "$age" -lt "$MAX_AGE" ]; then
          cat "$CACHE"
          exit 0
        fi
      fi

      json=$(${pkgs.curl}/bin/curl -sf "wttr.in/?format=j1" 2>/dev/null)
      ip=$(${pkgs.curl}/bin/curl -sf "https://ipecho.net/plain" 2>/dev/null)

      if [ -z "$json" ] || [ "$json" = "null" ]; then
        echo '{"text": "󰖐 --", "tooltip": "weather unavailable"}'
        exit 0
      fi

      # current hour index for hourly forecast data
      hour_idx=$(( $(date +%-H) / 3 ))

      updated=$(date '+%H:%M')

      echo "$json" | ${pkgs.jq}/bin/jq -c --arg ip "$ip" --argjson hi "$hour_idx" --arg updated "$updated" '
        def d(f): (f // "n/a") | if . == "" then "n/a" else . end;
        .current_condition[0] as $c |
        .nearest_area[0] as $a |
        .weather[0].hourly[$hi] as $h |
        ({"113":"󰖙","116":"󰖐","119":"󰖐","122":"󰖐","143":"󰖑","176":"󰖗","179":"󰙿","182":"󰖒","185":"󰖒","200":"󰖓","227":"󰼶","230":"󰼶","248":"󰖑","260":"󰖑","263":"󰖗","266":"󰖗","281":"󰖒","284":"󰖒","293":"󰖗","296":"󰖗","299":"󰖖","302":"󰖖","305":"󰖖","308":"󰖖","311":"󰖒","314":"󰖒","317":"󰙿","320":"󰙿","323":"󰙿","326":"󰙿","329":"󰼶","332":"󰼶","335":"󰼶","338":"󰼶","350":"󰖒","353":"󰖗","356":"󰖖","359":"󰖖","362":"󰖒","365":"󰖒","368":"󰙿","371":"󰼶","374":"󰖒","377":"󰖒","386":"󰖓","389":"󰖓","392":"󰙿","395":"󰼶"}[$c.weatherCode] // "󰖐") as $icon |
        (d($a.areaName[0].value) + ", " + d($a.region[0].value)) as $loc |
        {
          text: "\($icon) \(d($c.temp_F))°F",
          tooltip: "\(d($c.weatherDesc[0].value)) \(d($c.temp_F))°F (feels \(d($c.FeelsLikeF))°F)\nprecipitation: \(d($h.chanceofrain))% (\(d($c.precipInches))in)\nhumidity: \(d($c.humidity))%\nwind: \(d($c.windspeedMiles))mph \(d($c.winddir16Point))\n\n\($loc) (\($ip // "n/a"))\nupdated \($updated)"
        }
      ' | tee "$CACHE"
    '';

    networkScript = pkgs.writeShellScript "waybar-network" ''
      # prefer ethernet over wifi
      dev=$(${pkgs.networkmanager}/bin/nmcli -t -f TYPE,DEVICE,STATE device status 2>/dev/null | command grep ':connected$' | sort -t: -k1,1 | head -1 | cut -d: -f2)
      if [ -z "$dev" ]; then
        printf '{"text": "󰤭 disconnected", "tooltip": "no connection", "class": "disconnected"}\n'
        exit 0
      fi
      info=$(${pkgs.networkmanager}/bin/nmcli -t device show "$dev" 2>/dev/null)

      conn=$(echo "$info" | command grep 'GENERAL.CONNECTION:' | head -1 | cut -d: -f2-)
      mac=$(echo "$info" | command grep 'GENERAL.HWADDR:' | head -1 | cut -d: -f2-)
      addr=$(echo "$info" | command grep 'IP4.ADDRESS' | head -1 | cut -d: -f2-)
      gw=$(echo "$info" | command grep 'IP4.GATEWAY:' | head -1 | cut -d: -f2-)
      dns=$(echo "$info" | command grep 'IP4.DNS' | sed 's/.*://' | paste -sd ', ')
      domain=$(echo "$info" | command grep 'IP4.DOMAIN' | head -1 | cut -d: -f2-)
      ipv6=$(echo "$info" | command grep 'IP6.ADDRESS' | head -1 | cut -d: -f2-)
      type=$(echo "$info" | command grep 'GENERAL.TYPE:' | head -1 | cut -d: -f2-)

      ip=$(echo "$addr" | cut -d/ -f1)

      if [ -z "$conn" ] || [ -z "$ip" ]; then
        printf '{"text": "󰤭 disconnected", "tooltip": "no connection", "class": "disconnected"}\n'
        exit 0
      fi

      if [ "$type" = "wifi" ]; then
        signal=$(${pkgs.networkmanager}/bin/nmcli -t -f IN-USE,SIGNAL dev wifi list 2>/dev/null | command grep '^\*' | cut -d: -f2)
        freq=$(${pkgs.iw}/bin/iw dev "$dev" info 2>/dev/null | command grep 'channel' | sed 's/.*(\(.*\) MHz.*/\1/')
        band=""
        if [ -n "$freq" ]; then
          if [ "$freq" -lt 3000 ] 2>/dev/null; then band="2.4GHz"
          elif [ "$freq" -lt 6000 ] 2>/dev/null; then band="5GHz"
          else band="6GHz"; fi
        fi
        text="󰤨 $conn (''${signal}%) $ip"
        tooltip="interface       $dev\nssid            $conn (''${signal}% on ''${band:-unknown})\naddress         $addr\ngateway         $gw\ndns             $dns''${domain:+\ndomain          $domain}\nmac             $mac''${ipv6:+\nipv6            $ipv6}"
      else
        text="󰈀 $ip"
        tooltip="interface       $dev\nconnection      $conn\naddress         $addr\ngateway         $gw\ndns             $dns''${domain:+\ndomain          $domain}\nmac             $mac''${ipv6:+\nipv6            $ipv6}"
      fi

      printf '{"text": "%s", "tooltip": "%s", "class": "%s"}\n' "$text" "$tooltip" "$type"
    '';

    # uses impala (iwd) if available, falls back to wlctl (networkmanager)
    wifiTui = pkgs.writeShellScript "wifi-tui" ''
      if systemctl is-active --quiet iwd 2>/dev/null; then
        exec ${pkgs.impala}/bin/impala
      else
        exec ${pkgs.wlctl}/bin/wlctl
      fi
    '';
  in {
    programs.waybar = {
      enable = true;
      systemd.enable = true;
      settings = [
        {
          layer = "top";
          position = "top";
          height = 26;
          spacing = 0;

          modules-left = ["hyprland/workspaces" "custom/weather" "custom/pomodoro" "custom/media"];
          modules-center = ["clock"];
          modules-right = ["custom/caffeine" "custom/recording" "bluetooth" "custom/network" "pulseaudio" "pulseaudio#mic" "cpu" "memory" "power-profiles-daemon" "battery"];

          "hyprland/workspaces" = {
            format = "{icon}";
            format-icons = {
              active = "󱓻";
              default = "󱓼";
            };
            on-click = "activate";
            sort-by-number = true;
          };

          clock = {
            format = "{:%a %b %d  %H:%M:%S}";
            interval = 1;
            tooltip = false;
          };

          "custom/weather" = {
            exec = "${weatherScript} status";
            return-type = "json";
            interval = 900;
            tooltip = true;
          };

          "custom/pomodoro" = {
            exec = "${pomodoroScript} status";
            return-type = "json";
            interval = 1;
            on-click = "${pomodoroScript} start";
            on-click-right = "${pomodoroScript} stop";
            tooltip = true;
          };

          cpu = {
            format = "󰘚 {usage}%";
            interval = 5;
            on-click = "${pkgs.wezterm}/bin/wezterm start --class btop -- btop";
          };

          memory = {
            format = "󰍛 {percentage}%";
            tooltip-format = "{used:0.1f}G / {total:0.1f}G";
            interval = 5;
          };

          pulseaudio = {
            format = "{icon} {volume}%";
            format-muted = "󰖁 muted";
            format-icons = {
              default = ["󰕿" "󰖀" "󰕾"];
            };
            on-click = "${pkgs.pavucontrol}/bin/pavucontrol";
          };

          bluetooth = {
            format-on = "󰂯";
            format-off = "󰂲";
            format-connected = "󰂱 {device_alias}";
            on-click = "${pkgs.wezterm}/bin/wezterm start --class bluetui -- bluetui";
          };

          "pulseaudio#mic" = {
            format = "{format_source}";
            format-source = "󰍬";
            format-source-muted = "󰍭";
            on-click = "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle";
            tooltip-format = "Mic: {source_volume}%";
          };

          "custom/network" = {
            exec = "${networkScript}";
            return-type = "json";
            interval = 5;
            on-click = "${pkgs.wezterm}/bin/wezterm start --class wifi-tui -- ${wifiTui}";
          };

          battery = {
            format = "{icon} {capacity}%";
            format-charging = "󰂄 {capacity}%";
            format-plugged = "󰚥 {capacity}%";
            format-full = "󰁹 full";
            format-icons = ["󰂎" "󰁺" "󰁻" "󰁼" "󰁽" "󰁾" "󰁿" "󰂀" "󰂁" "󰂂" "󰁹"];
            states = {
              warning = 20;
              critical = 10;
            };
            tooltip-format-discharging = "time to empty   {time}\npower draw      {power:.1f}W\nhealth          {health}%\ncycles          {cycles}";
            tooltip-format-charging = "time to full    {time}\ncharge rate     {power:.1f}W\nhealth          {health}%\ncycles          {cycles}";
            tooltip-format-full = "status          full\nhealth          {health}%\ncycles          {cycles}";
            tooltip-format-plugged = "status          plugged\nhealth          {health}%\ncycles          {cycles}";
            interval = 5;
          };

          power-profiles-daemon = {
            format = "{icon}";
            format-icons = {
              default = "󰗑";
              performance = "󱐌";
              balanced = "󰗑";
              power-saver = "󰌪";
            };
            tooltip-format = "Profile: {profile}";
          };

          "custom/media" = {
            exec = "${pkgs.playerctl}/bin/playerctl --follow metadata --format '{\"text\": \"{{artist}} - {{title}}\", \"tooltip\": \"{{playerName}}: {{artist}} - {{title}}\", \"class\": \"{{status}}\"}' 2>/dev/null";
            return-type = "json";
            max-length = 35;
            on-click = "${pkgs.playerctl}/bin/playerctl play-pause";
            on-scroll-up = "${pkgs.playerctl}/bin/playerctl next";
            on-scroll-down = "${pkgs.playerctl}/bin/playerctl previous";
          };

          "custom/caffeine" = {
            exec = "${caffeineScript} status";
            return-type = "json";
            interval = 2;
            on-click = "${caffeineScript} toggle";
            tooltip = true;
          };

          "custom/recording" = {
            exec = "pgrep -x wl-screenrec > /dev/null && echo '󰻂 REC' || echo ''";
            interval = 1;
            return-type = "";
          };
        }
      ];

      style = ''
        * {
          font-family: "JetBrainsMono Nerd Font";
          font-size: 12px;
          border: none;
          border-radius: 0;
          min-height: 0;
        }

        window#waybar {
          background: ${c.bg};
          color: ${c.text};
        }

        #workspaces button {
          padding: 0 6px;
          margin: 0 1.5px;
          color: ${c.surface1};
          background: transparent;
        }

        #workspaces button.active {
          color: ${c.accent};
        }

        #workspaces button:hover {
          background: ${c.mantle};
        }

        #clock {
          padding: 0 10px;
          color: ${c.text};
        }

        #custom-weather {
          padding: 0 8px;
          color: ${c.subtext0};
        }

        #custom-pomodoro {
          padding: 0 8px;
          color: ${c.surface1};
        }

        #custom-pomodoro.active {
          color: ${c.accent};
        }

        #cpu, #memory, #pulseaudio, #custom-network, #bluetooth, #battery, #power-profiles-daemon {
          padding: 0 8px;
          color: ${c.text};
        }

        #pulseaudio.muted {
          color: ${c.surface1};
        }

        #custom-network.disconnected {
          color: ${c.surface1};
        }

        #bluetooth.off {
          color: ${c.surface1};
        }

        #custom-media {
          padding: 0 8px;
          color: ${c.subtext0};
        }

        #custom-media.Playing {
          color: ${c.accent};
        }

        #custom-media.Paused {
          color: ${c.surface1};
        }

        #custom-caffeine {
          padding: 0 8px;
          color: ${c.surface1};
        }

        #custom-caffeine.active {
          color: ${c.red};
        }

        #custom-recording {
          color: ${c.red};
          padding: 0 8px;
        }

        #battery.warning {
          color: ${c.red};
        }

        #battery.critical {
          color: ${c.red};
          animation: blink 1s linear infinite;
        }

        @keyframes blink {
          to { color: ${c.bg}; }
        }

        tooltip {
          background: ${c.mantle};
          border: 1px solid ${c.surface0};
          border-radius: 4px;
          padding: 2px;
        }
      '';
    };
  };
}
