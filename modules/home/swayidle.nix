_: {
  flake.homeModules.swayidle = {pkgs, ...}: {
    services.swayidle = {
      enable = true;
      timeouts = [
        {
          timeout = 300;
          command = "${pkgs.swaylock-effects}/bin/swaylock -f";
        }
        {
          timeout = 330;
          command = "niri msg action power-off-monitors";
          resumeCommand = "niri msg action power-on-monitors";
        }
      ];
      events = {
        before-sleep = "${pkgs.swaylock-effects}/bin/swaylock -f";
        lock = "${pkgs.swaylock-effects}/bin/swaylock -f";
      };
    };
  };
}
