_: {
  flake.modules.homeManager.hypridle =
    {
      pkgs,
      lib,
      config,
      osConfig,
      ...
    }:
    let
      niri = lib.getExe' osConfig.programs.niri.package "niri";
      loginctl = lib.getExe' pkgs.systemd "loginctl";
      systemctl = lib.getExe' pkgs.systemd "systemctl";
      makoctl = lib.getExe' config.services.mako.package "makoctl";
    in
    {
      systemd.user.services.hyprlock = {
        Unit = {
          Description = "Lock screen";
          ConditionEnvironment = "WAYLAND_DISPLAY";
          PartOf = [ config.wayland.systemd.target ];
        };
        Service = {
          ExecStartPre = [
            "-${makoctl} mode -a lock"
            "-${niri} msg action do-screen-transition --delay-ms 300"
          ];
          ExecStart = lib.getExe config.programs.hyprlock.package;
          ExecStopPost = "-${makoctl} mode -r lock";
        };
      };

      services.hypridle = {
        enable = true;
        settings = {
          general = {
            # keepassxc and Mod+Escape lock through logind too
            lock_cmd = "${systemctl} --user start hyprlock.service";
            # lock-before-sleep in niri.nix waits instead
            inhibit_sleep = 0;
            after_sleep_cmd = "${niri} msg action power-on-monitors";
          };

          # nothing suspends the machine
          listener = [
            {
              timeout = 300;
              "on-timeout" = "${loginctl} lock-session";
            }
            {
              timeout = 330;
              "on-timeout" = "${niri} msg action power-off-monitors";
              "on-resume" = "${niri} msg action power-on-monitors";
            }
          ];
        };
      };
    };
}
