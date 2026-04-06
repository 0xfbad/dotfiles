_: {
  flake.homeModules.hyprlock = {
    config,
    pkgs,
    ...
  }: let
    c = config.colors.hypr;
    inherit (config.colors) rounding;

    jq = "${pkgs.jq}/bin/jq";
    playerctl = "${pkgs.playerctl}/bin/playerctl";

    # reads the quickshell weather cache, no extra network calls
    weatherCmd = ''cmd[update:300000] [ -f /tmp/qs-weather ] && ${jq} -r '"\(.temp)  \(.desc), \(.location)"' /tmp/qs-weather || echo ""'';

    mediaCmd = ''cmd[update:3000] ${playerctl} metadata --format '{{artist}} - {{title}}' 2>/dev/null || echo ""'';

    greetingCmd = ''cmd[update:60000] h=$(date +%H); if [ "$h" -lt 6 ]; then echo "good night"; elif [ "$h" -lt 12 ]; then echo "good morning"; elif [ "$h" -lt 18 ]; then echo "good afternoon"; else echo "good evening"; fi'';
  in {
    programs.hyprlock = {
      enable = true;
      settings = {
        general = {
          hide_cursor = true;
          grace = 5;
          ignore_empty_input = true;
          text_trim = true;
        };

        # screenshot of current screen with frosted blur
        background = [
          {
            monitor = "";
            path = "screenshot";
            blur_passes = 3;
            blur_size = 6;
            contrast = 0.9;
            brightness = 0.7;
            vibrancy = 0.2;
            vibrancy_darkness = 0.0;
          }
        ];

        # dark panel behind the clock and input area
        shape = [
          {
            monitor = "";
            size = "420, 520";
            color = "rgba(0, 0, 0, 0.45)";
            inherit rounding;
            border_size = 0;
            position = "0, 0";
            halign = "center";
            valign = "center";
            zindex = 1;
          }
        ];

        label = [
          # hours
          {
            monitor = "";
            text = ''cmd[update:1000] echo "<b>$(date +"%H")</b>"'';
            color = c.accent;
            font_size = 120;
            font_family = "JetBrainsMono Nerd Font";
            position = "0, 12%";
            halign = "center";
            valign = "center";
            zindex = 5;
            shadow_passes = 2;
            shadow_size = 3;
            shadow_color = "rgb(0,0,0)";
            shadow_boost = 1.2;
          }

          # minutes
          {
            monitor = "";
            text = ''cmd[update:1000] echo "$(date +"%M")"'';
            color = c.text;
            font_size = 120;
            font_family = "JetBrainsMono Nerd Font";
            position = "0, 0%";
            halign = "center";
            valign = "center";
            zindex = 5;
            shadow_passes = 2;
            shadow_size = 3;
            shadow_color = "rgb(0,0,0)";
            shadow_boost = 1.2;
          }

          # date
          {
            monitor = "";
            text = ''cmd[update:60000] echo "$(date +"%A, %B %d")"'';
            color = c.text;
            font_size = 14;
            font_family = "JetBrainsMono Nerd Font";
            position = "0, -8%";
            halign = "center";
            valign = "center";
            zindex = 5;
            shadow_passes = 1;
            shadow_boost = 0.5;
          }

          # greeting
          {
            monitor = "";
            text = greetingCmd;
            color = c.text;
            font_size = 11;
            font_family = "JetBrainsMono Nerd Font";
            position = "0, -10%";
            halign = "center";
            valign = "center";
            zindex = 5;
          }

          # weather from quickshell cache
          {
            monitor = "";
            text = weatherCmd;
            color = c.text;
            font_size = 11;
            font_family = "JetBrainsMono Nerd Font";
            position = "0, -2%";
            halign = "center";
            valign = "top";
            zindex = 5;
            shadow_passes = 1;
            shadow_boost = 0.5;
          }

          # now playing
          {
            monitor = "";
            text = mediaCmd;
            color = c.text;
            font_size = 11;
            font_family = "JetBrainsMono Nerd Font";
            position = "0, 3%";
            halign = "center";
            valign = "bottom";
            zindex = 5;
            shadow_passes = 1;
            shadow_boost = 0.5;
          }
        ];

        input-field = [
          {
            monitor = "";
            size = "300, 50";
            outline_thickness = 2;
            dots_size = 0.2;
            dots_spacing = 0.2;
            dots_center = true;
            outer_color = c.accent;
            inner_color = c.surface0Alpha;
            font_color = c.text;
            check_color = c.green;
            fail_color = c.red;
            capslock_color = c.yellow;
            fade_on_empty = true;
            fade_timeout = 5000;
            font_family = "JetBrainsMono Nerd Font";
            placeholder_text = ''<span foreground="#cdd6f4"><i>locked</i></span>'';
            fail_text = ''<i>$FAIL <b>($ATTEMPTS)</b></i>'';
            hide_input = false;
            inherit rounding;
            position = "0, -17%";
            halign = "center";
            valign = "center";
            zindex = 10;
          }
        ];
      };
    };
  };
}
