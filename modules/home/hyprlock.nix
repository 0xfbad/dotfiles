_: {
  flake.homeModules.hyprlock = {
    config,
    pkgs,
    ...
  }: let
    c = config.colors.hypr;
    inherit (config.colors) rounding;

    jq = "${pkgs.jq}/bin/jq";

    # reads the quickshell weather cache, no extra network calls
    weatherCmd = ''cmd[update:300000] [ -f /tmp/qs-weather ] && ${jq} -r '"\(.temp)  \(.desc), \(.location)"' /tmp/qs-weather || echo " "'';

    greetingCmd = ''cmd[update:60000] h=$(date +%H); if [ "$h" -lt 6 ]; then echo "good night, $USER"; elif [ "$h" -lt 12 ]; then echo "good morning, $USER"; elif [ "$h" -lt 18 ]; then echo "good afternoon, $USER"; else echo "good evening, $USER"; fi'';
  in {
    programs.hyprlock = {
      enable = true;
      settings = {
        general = {
          hide_cursor = true;
          ignore_empty_input = true;
          text_trim = true;
        };

        # transparent background, compositor blur handles the rest via layerrule
        background = [
          {
            monitor = "";
            path = "screenshot";
            blur_passes = 3;
            blur_size = 8;
            brightness = 0.7;
            contrast = 0.9;
            vibrancy = 0.2;
          }
        ];

        # pixel offsets from center, computed from font heights:
        # hours(120px) +150, gap 10, minutes(120px) +20, gap 18,
        # greeting(14px) -65, gap 29, date(18px) -110, gap 36,
        # input(50px) -180. weather anchored 30px from top edge.
        label = [
          # hours
          {
            monitor = "";
            text = ''cmd[update:1000] echo "<b>$(date +"%H")</b>"'';
            color = c.accent;
            font_size = 120;
            font_family = "JetBrainsMono Nerd Font";
            position = "0, 150";
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
            position = "0, 20";
            halign = "center";
            valign = "center";
            zindex = 5;
            shadow_passes = 2;
            shadow_size = 3;
            shadow_color = "rgb(0,0,0)";
            shadow_boost = 1.2;
          }

          # greeting
          {
            monitor = "";
            text = greetingCmd;
            color = c.text;
            font_size = 11;
            font_family = "JetBrainsMono Nerd Font";
            position = "0, -65";
            halign = "center";
            valign = "center";
            zindex = 5;
          }

          # date
          {
            monitor = "";
            text = ''cmd[update:60000] echo "$(date +"%A, %B %d")"'';
            color = c.text;
            font_size = 14;
            font_family = "JetBrainsMono Nerd Font";
            position = "0, -110";
            halign = "center";
            valign = "center";
            zindex = 5;
            shadow_passes = 1;
            shadow_boost = 0.5;
          }

          # weather from quickshell cache
          {
            monitor = "";
            text = weatherCmd;
            color = c.text;
            font_size = 11;
            font_family = "JetBrainsMono Nerd Font";
            position = "0, -30";
            halign = "center";
            valign = "top";
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
            placeholder_text = "locked";
            fail_text = ''<i>$FAIL <b>($ATTEMPTS)</b></i>'';
            hide_input = false;
            inherit rounding;
            position = "0, -180";
            halign = "center";
            valign = "center";
            zindex = 10;
          }
        ];
      };
    };
  };
}
