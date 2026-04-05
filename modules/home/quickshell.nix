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
            printf '{"icon":"local_cafe","active":true}\n'
          else
            rm -f "$STATE" 2>/dev/null
            printf '{"icon":"local_cafe","active":false}\n'
          fi
          ;;
      esac
    '';

    weatherScript = pkgs.writeShellScript "qs-weather" ''
      CACHE="/tmp/qs-weather"
      CACHE_SCRIPT="/tmp/qs-weather-script"
      MAX_AGE=900
      CURL="${pkgs.curl}/bin/curl"
      JQ="${pkgs.jq}/bin/jq"

      if [ "$1" = "--refresh" ]; then
        rm -f "$CACHE"
      fi

      SELF="$(readlink -f "$0")"
      if [ -f "$CACHE_SCRIPT" ] && [ "$(cat "$CACHE_SCRIPT")" != "$SELF" ]; then
        rm -f "$CACHE"
      fi
      echo "$SELF" > "$CACHE_SCRIPT"

      if [ -f "$CACHE" ] && [ -s "$CACHE" ]; then
        age=$(( $(date +%s) - $(stat -c %Y "$CACHE") ))
        if [ "$age" -lt "$MAX_AGE" ]; then
          cat "$CACHE"
          exit 0
        fi
      fi

      fail() {
        printf '{"icon":"cloud","temp":"--","desc":"","feelsLike":"","humidity":"","wind":"","location":"","rain":"","pubIp":"","hourly":[],"tomorrow":null,"error":"%s"}\n' "$1"
        exit 0
      }

      # geolocate via ip
      geo=$($CURL -sf --max-time 5 "https://ipinfo.io/json" 2>/dev/null)
      if [ -z "$geo" ]; then
        fail "geolocation failed"
      fi

      loc=$(echo "$geo" | $JQ -r '.loc // empty' 2>/dev/null)
      city=$(echo "$geo" | $JQ -r '.city // empty' 2>/dev/null)
      region=$(echo "$geo" | $JQ -r '.region // empty' 2>/dev/null)
      pub_ip=$(echo "$geo" | $JQ -r '.ip // empty' 2>/dev/null)

      if [ -z "$loc" ]; then
        fail "no coordinates from ipinfo"
      fi

      lat=$(echo "$loc" | cut -d, -f1)
      lon=$(echo "$loc" | cut -d, -f2)

      # fetch from open-meteo (WMO codes, no api key)
      weather=$($CURL -sf --max-time 10 \
        "https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&current=temperature_2m,relative_humidity_2m,apparent_temperature,weather_code,wind_speed_10m,wind_direction_10m&hourly=weather_code,temperature_2m&daily=weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max&temperature_unit=fahrenheit&wind_speed_unit=mph&timezone=auto&forecast_days=2" 2>/dev/null)
      curl_exit=$?

      if [ -z "$weather" ]; then
        if [ "$curl_exit" -eq 6 ]; then fail "dns resolution failed"
        elif [ "$curl_exit" -eq 7 ]; then fail "connection refused"
        elif [ "$curl_exit" -eq 28 ]; then fail "request timed out"
        else fail "open-meteo request failed (curl $curl_exit)"
        fi
      fi

      echo "$weather" | $JQ -c --arg city "$city" --arg region "$region" --arg pip "$pub_ip" '
        def wmo_icon: . as $c | {"0":"sunny","1":"sunny","2":"partly_cloudy_day","3":"cloud","45":"foggy","48":"foggy","51":"rainy","53":"rainy","55":"rainy","56":"ac_unit","57":"ac_unit","61":"rainy","63":"rainy","65":"rainy","66":"ac_unit","67":"ac_unit","71":"cloudy_snowing","73":"cloudy_snowing","75":"cloudy_snowing","77":"cloudy_snowing","80":"rainy","81":"rainy","82":"rainy","85":"cloudy_snowing","86":"cloudy_snowing","95":"thunderstorm","96":"thunderstorm","99":"thunderstorm"} | .[$c | tostring] // "cloud";
        def wmo_desc: . as $c | {"0":"Clear","1":"Clear","2":"Partly cloudy","3":"Overcast","45":"Fog","48":"Fog","51":"Drizzle","53":"Drizzle","55":"Drizzle","56":"Freezing drizzle","57":"Freezing drizzle","61":"Light rain","63":"Rain","65":"Heavy rain","66":"Freezing rain","67":"Freezing rain","71":"Light snow","73":"Snow","75":"Heavy snow","77":"Snow grains","80":"Light showers","81":"Showers","82":"Heavy showers","85":"Snow showers","86":"Heavy snow showers","95":"Thunderstorm","96":"Thunderstorm with hail","99":"Thunderstorm with hail"} | .[$c | tostring] // "Unknown";
        def wind_dir: if . < 22.5 then "N" elif . < 67.5 then "NE" elif . < 112.5 then "E" elif . < 157.5 then "SE" elif . < 202.5 then "S" elif . < 247.5 then "SW" elif . < 292.5 then "W" elif . < 337.5 then "NW" else "N" end;
        def to12h: if . == 0 then "12 AM" elif . < 12 then "\(.) AM" elif . == 12 then "12 PM" else "\(. - 12) PM" end;

        (now | floor) as $now_ts |
        . as $root |

        [range($root.hourly.time | length) | . as $i |
          select(($root.hourly.time[$i] | sub("T"; " ") | strptime("%Y-%m-%d %H:%M") | mktime) > $now_ts) |
          {time: ($root.hourly.time[$i] | split("T")[1] | split(":")[0] | tonumber | to12h),
           icon: ($root.hourly.weather_code[$i] | wmo_icon),
           temp: ($root.hourly.temperature_2m[$i] | round | tostring)}
        ] | .[0:4] as $hourly |

        (if ($root.daily.time | length) > 1 then {
          day: ($root.daily.time[1] | split("-")[2]),
          icon: ($root.daily.weather_code[1] | wmo_icon),
          high: ($root.daily.temperature_2m_max[1] | round | tostring),
          low: ($root.daily.temperature_2m_min[1] | round | tostring)
        } else null end) as $tomorrow |

        {
          icon: ($root.current.weather_code | wmo_icon),
          temp: "\($root.current.temperature_2m | round)°F",
          feelsLike: "\($root.current.apparent_temperature | round)°F",
          humidity: "\($root.current.relative_humidity_2m)%",
          wind: "\($root.current.wind_speed_10m | round) mph \($root.current.wind_direction_10m | wind_dir)",
          desc: ($root.current.weather_code | wmo_desc),
          location: ($city + ", " + $region),
          pubIp: $pip,
          rain: (($root.daily.precipitation_probability_max[0] // 0 | tostring) + "% chance today"),
          hourly: $hourly,
          tomorrow: $tomorrow
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
            if [ "$signal" -ge 75 ]; then echo "network_wifi"
            elif [ "$signal" -ge 50 ]; then echo "network_wifi_3_bar"
            elif [ "$signal" -ge 25 ]; then echo "network_wifi_2_bar"
            else echo "network_wifi_1_bar"; fi
          else echo "signal_wifi_off"; fi
        else echo "wifi_off"; fi
      }

      get_wifi_signal() { local signal=$(${pkgs.networkmanager}/bin/nmcli -f IN-USE,SIGNAL dev wifi 2>/dev/null | command grep '^\*' | awk '{print $2}'); echo "''${signal:-0}"; }
      get_ip() {
        local dev=$(${pkgs.networkmanager}/bin/nmcli -t -f TYPE,DEVICE,STATE device status 2>/dev/null | command grep ':connected$' | head -1 | cut -d: -f2)
        [ -z "$dev" ] && { echo ""; return; }
        ${pkgs.networkmanager}/bin/nmcli -t device show "$dev" 2>/dev/null | command grep 'IP4.ADDRESS' | head -1 | cut -d: -f2- | cut -d/ -f1
      }

      power_profile=$(${pkgs.power-profiles-daemon}/bin/powerprofilesctl get 2>/dev/null || echo "balanced")

      case "$power_profile" in
        performance) power_icon="bolt" ;;
        power-saver) power_icon="battery_saver" ;;
        *) power_icon="tune" ;;
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
      exec ${pkgs.wlctl}/bin/wlctl
    '';

    cavaConfig = pkgs.writeText "qs-cava.conf" ''
      [general]
      bars = 12
      framerate = 30
      [output]
      method = raw
      raw_target = /dev/stdout
      data_format = ascii
      ascii_max_range = 100
      bar_delimiter = 59
      frame_delimiter = 10
      [smoothing]
      monstercat = 1
    '';

    cavaScript = pkgs.writeShellScript "qs-cava" ''
      exec ${pkgs.cava}/bin/cava -p ${cavaConfig}
    '';

    # json config files generated from nix values
    colorsJson = builtins.toJSON {
      inherit (c) bg mantle surface0 surface1 subtext0 text accent red blue peach green yellow;
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
      cava = "${cavaScript}";
    };
    configDir = pkgs.runCommand "quickshell-config" {} ''
      mkdir -p $out
      cp ${./quickshell}/*.qml $out/
      echo ${lib.escapeShellArg colorsJson} > $out/colors.json
      echo ${lib.escapeShellArg scriptsJson} > $out/scripts.json
    '';
  in {
    home.packages = [pkgs.quickshell pkgs.brightnessctl pkgs.cava];

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
        # config path changes on rebuild, triggering unit diff for sd-switch
        Environment = ["QS_CONFIG=${configDir}"];
      };
      Install.WantedBy = ["graphical-session.target"];
    };

    # restart quickshell when config changes on rebuild
    home.activation.restartQuickshell = lib.hm.dag.entryAfter ["reloadSystemd"] ''
      if ${pkgs.systemd}/bin/systemctl --user is-active quickshell.service > /dev/null 2>&1; then
        ${pkgs.systemd}/bin/systemctl --user restart quickshell.service || true
      fi
    '';
  };
}
