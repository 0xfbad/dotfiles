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
      # the unit pins PATH to bash alone, so nothing here resolves by name
      niri = lib.getExe' osConfig.programs.niri.package "niri";
      loginctl = lib.getExe' pkgs.systemd "loginctl";
      pgrep = lib.getExe' pkgs.procps "pgrep";
      makoctl = lib.getExe' config.services.mako.package "makoctl";
      hyprlock = lib.getExe config.programs.hyprlock.package;

      lock = pkgs.writeShellScript "lock-session" ''
        ${pgrep} -x hyprlock >/dev/null && exit 0

        ${makoctl} mode -a lock >/dev/null
        ${niri} msg action do-screen-transition --delay-ms 300
        ${hyprlock}
        ${makoctl} mode -r lock >/dev/null
      '';
    in
    {
      services.hypridle = {
        enable = true;
        settings = {
          general = {
            # the logind Lock signal is the single lock path, keepassxc and Mod+Escape use it too
            lock_cmd = "${lock}";
            before_sleep_cmd = "${loginctl} lock-session";
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
