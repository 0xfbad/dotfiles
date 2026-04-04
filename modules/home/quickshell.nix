_: {
  flake.homeModules.quickshell = {
    config,
    pkgs,
    lib,
    ...
  }: let
    c = config.colors;

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
            printf '{"icon":"󰅶","active":true}\n'
          else
            rm -f "$STATE" 2>/dev/null
            printf '{"icon":"󰛊","active":false}\n'
          fi
          ;;
      esac
    '';

    weatherScript = pkgs.writeShellScript "qs-weather" ''
      CACHE="/tmp/qs-weather"
      CACHE_SCRIPT="/tmp/qs-weather-script"
      MAX_AGE=900

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
      pub_ip=$(${pkgs.curl}/bin/curl -sf --max-time 3 "ifconfig.me" 2>/dev/null || echo "")

      if [ -z "$json" ] || [ "$json" = "null" ]; then
        printf '{"icon":"󰖐","temp":"--","desc":"","feelsLike":"","humidity":"","wind":"","location":"","rain":"","pubIp":"","hourly":[],"tomorrow":null}\n'
        exit 0
      fi

      hour_idx=$(( $(date +%-H) / 3 ))

      echo "$json" | ${pkgs.jq}/bin/jq -c --argjson hi "$hour_idx" --arg pip "$pub_ip" '
        {"113":"󰖙","116":"󰖐","119":"󰖐","122":"󰖐","143":"󰖑","176":"󰖗","179":"󰙿","182":"󰖒","185":"󰖒","200":"󰖓","227":"󰼶","230":"󰼶","248":"󰖑","260":"󰖑","263":"󰖗","266":"󰖗","281":"󰖒","284":"󰖒","293":"󰖗","296":"󰖗","299":"󰖖","302":"󰖖","305":"󰖖","308":"󰖖","311":"󰖒","314":"󰖒","317":"󰙿","320":"󰙿","323":"󰙿","326":"󰙿","329":"󰼶","332":"󰼶","335":"󰼶","338":"󰼶","350":"󰖒","353":"󰖗","356":"󰖖","359":"󰖖","362":"󰖒","365":"󰖒","368":"󰙿","371":"󰼶","374":"󰖒","377":"󰖒","386":"󰖓","389":"󰖓","392":"󰙿","395":"󰼶"} as $icons |
        .current_condition[0] as $cc |
        .weather[0].hourly[$hi] as $ch |
        ($icons[$cc.weatherCode] // "󰖐") as $icon |
        {
          icon: $icon,
          temp: "\($cc.temp_F)°F",
          feelsLike: "\($cc.FeelsLikeF)°F",
          humidity: "\($cc.humidity)%",
          wind: "\($cc.windspeedMiles) mph \($cc.winddir16Point)",
          desc: ($cc.weatherDesc[0].value // ""),
          location: ((.nearest_area[0].areaName[0].value // "") + ", " + (.nearest_area[0].region[0].value // "")),
          pubIp: $pip,
          rain: (($ch.chanceofrain // "0") + "% chance, " + (($ch.precipInches // "0") | if . == "0.0" or . == "0" then "none" else "\(.) in" end)),
          hourly: ([.weather[0].hourly[$hi+1:][]] + [.weather[1].hourly[:][]]) | .[0:4] | [.[] | {
            time: (.time | tonumber / 100 | floor | if . == 0 then "12 AM" elif . < 12 then "\(.) AM" elif . == 12 then "12 PM" else "\(. - 12) PM" end),
            icon: ($icons[.weatherCode] // "󰖐"),
            temp: .tempF
          }],
          tomorrow: (.weather[1] // null) | if . then {
            day: (.date | split("-") | .[2:3] | .[0] | tonumber | tostring),
            icon: ($icons[.hourly[4].weatherCode] // "󰖐"),
            high: .maxtempF,
            low: .mintempF
          } else null end
        }
      ' | tee "$CACHE"
    '';

    sysInfoScript = pkgs.writeShellScript "qs-sysinfo" ''
      get_wifi_status() { ${pkgs.networkmanager}/bin/nmcli -t -f WIFI g 2>/dev/null || echo "disabled"; }
      get_wifi_ssid() { local ssid=$(${pkgs.networkmanager}/bin/nmcli -t -f ACTIVE,SSID dev wifi 2>/dev/null | command grep '^yes' | cut -d: -f2); echo "''${ssid:-}"; }
      get_wifi_icon() {
        local status=$(get_wifi_status)
        local ssid=$(get_wifi_ssid)
        if [ "$status" = "enabled" ]; then
          if [ -n "$ssid" ]; then
            local signal=$(${pkgs.networkmanager}/bin/nmcli -f IN-USE,SIGNAL dev wifi 2>/dev/null | command grep '^\*' | awk '{print $2}')
            [ -z "$signal" ] && signal=0
            if [ "$signal" -ge 75 ]; then echo "󰤨"
            elif [ "$signal" -ge 50 ]; then echo "󰤥"
            elif [ "$signal" -ge 25 ]; then echo "󰤢"
            else echo "󰤟"; fi
          else echo "󰤯"; fi
        else echo "󰤮"; fi
      }

      get_wifi_signal() { local signal=$(${pkgs.networkmanager}/bin/nmcli -f IN-USE,SIGNAL dev wifi 2>/dev/null | command grep '^\*' | awk '{print $2}'); echo "''${signal:-0}"; }
      get_ip() {
        local dev=$(${pkgs.networkmanager}/bin/nmcli -t -f TYPE,DEVICE,STATE device status 2>/dev/null | command grep ':connected$' | head -1 | cut -d: -f2)
        [ -z "$dev" ] && { echo ""; return; }
        ${pkgs.networkmanager}/bin/nmcli -t device show "$dev" 2>/dev/null | command grep 'IP4.ADDRESS' | head -1 | cut -d: -f2- | cut -d/ -f1
      }

      power_profile=$(${pkgs.power-profiles-daemon}/bin/powerprofilesctl get 2>/dev/null || echo "balanced")

      case "$power_profile" in
        performance) power_icon="󱐌" ;;
        power-saver) power_icon="󰌪" ;;
        *) power_icon="󰗑" ;;
      esac

      ${pkgs.jq}/bin/jq -n -c \
        --arg wifi_status "$(get_wifi_status)" \
        --arg wifi_ssid "$(get_wifi_ssid)" \
        --arg wifi_icon "$(get_wifi_icon)" \
        --arg wifi_signal "$(get_wifi_signal)" \
        --arg ip "$(get_ip)" \
        --arg power_profile "$power_profile" \
        --arg power_icon "$power_icon" \
        '{
          wifi: { status: $wifi_status, ssid: $wifi_ssid, icon: $wifi_icon, signal: $wifi_signal, ip: $ip },
          power: { profile: $power_profile, icon: $power_icon }
        }'
    '';

    wifiTui = pkgs.writeShellScript "wifi-tui" ''
      if systemctl is-active --quiet iwd 2>/dev/null; then
        exec ${pkgs.impala}/bin/impala
      else
        exec ${pkgs.wlctl}/bin/wlctl
      fi
    '';

    # json config files generated from nix values
    colorsJson = builtins.toJSON {
      inherit (c) bg mantle surface0 surface1 subtext0 text accent red;
      blue = "#89b4fa";
      peach = "#fab387";
      green = "#a6e3a1";
      yellow = "#f9e2af";
    };

    scriptsJson = builtins.toJSON {
      caffeine = "${caffeineScript}";
      weather = "${weatherScript}";
      sysinfo = "${sysInfoScript}";
      wifiTui = "${wifiTui}";
      wezterm = "${pkgs.wezterm}/bin/wezterm";
      pavucontrol = "${pkgs.pavucontrol}/bin/pavucontrol";
      brightnessctl = "${pkgs.brightnessctl}/bin/brightnessctl";
      swww = "${pkgs.swww}/bin/swww";
    };
    configDir = pkgs.runCommand "quickshell-config" {} ''
      mkdir -p $out
      cp ${./quickshell}/*.qml $out/
      echo ${lib.escapeShellArg colorsJson} > $out/colors.json
      echo ${lib.escapeShellArg scriptsJson} > $out/scripts.json
    '';
  in {
    home.packages = [pkgs.quickshell pkgs.brightnessctl];

    xdg.configFile."quickshell".source = configDir;

    systemd.user.services.quickshell = {
      Unit = {
        Description = "Quickshell desktop shell";
        PartOf = ["graphical-session.target"];
        After = ["graphical-session.target"];
      };
      Service = {
        ExecStart = "${lib.getExe pkgs.quickshell}";
        Restart = "on-failure";
        RestartSec = 2;
      };
      Install.WantedBy = ["graphical-session.target"];
    };
  };
}
