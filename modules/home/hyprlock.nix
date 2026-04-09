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
          grace = 5;
          ignore_empty_input = true;
          text_trim = true;
        };

        # transparent background, compositor blur handles the rest via layerrule
        background = [
          {
            monitor = "";
            path = "";
            color = "rgba(1e1e2eaa)";
          }
        ];

        label = [
          # hours (pixel offset, grouped with minutes + greeting)
          {
            monitor = "";
            text = ''cmd[update:1000] echo "<b>$(date +"%H")</b>"'';
            color = c.accent;
            font_size = 120;
            font_family = "JetBrainsMono Nerd Font";
            position = "0, 75";
            halign = "center";
            valign = "center";
            zindex = 5;
            shadow_passes = 2;
            shadow_size = 3;
            shadow_color = "rgb(0,0,0)";
            shadow_boost = 1.2;
          }

          # minutes (pixel offset, grouped with hours + greeting)
          {
            monitor = "";
            text = ''cmd[update:1000] echo "$(date +"%M")"'';
            color = c.text;
            font_size = 120;
            font_family = "JetBrainsMono Nerd Font";
            position = "0, -55";
            halign = "center";
            valign = "center";
            zindex = 5;
            shadow_passes = 2;
            shadow_size = 3;
            shadow_color = "rgb(0,0,0)";
            shadow_boost = 1.2;
          }

          # greeting (pixel offset, grouped with hours + minutes)
          {
            monitor = "";
            text = greetingCmd;
            color = c.text;
            font_size = 11;
            font_family = "JetBrainsMono Nerd Font";
            position = "0, -115";
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
            position = "0, -15%";
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
            position = "0, -2%";
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
            placeholder_text = ''<span foreground="#cdd6f4"><i>locked</i></span>'';
            fail_text = ''<i>$FAIL <b>($ATTEMPTS)</b></i>'';
            hide_input = false;
            inherit rounding;
            position = "0, -22%";
            halign = "center";
            valign = "center";
            zindex = 10;
          }
        ];
      };
    };
  };
}
