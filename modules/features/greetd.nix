_: {
  flake.nixosModules.greetd = {pkgs, ...}: {
    services.greetd = {
      enable = true;
      settings.default_session = {
        command = "${pkgs.tuigreet}/bin/tuigreet --time --remember-session --asterisks --issue --cmd niri-session";
        user = "greeter";
      };
    };

    # prevent late boot messages from printing over tuigreet
    systemd.services.greetd.serviceConfig = {
      Type = "idle";
      StandardInput = "tty";
      StandardOutput = "tty";
      StandardError = "journal";
      TTYReset = true;
      TTYVHangup = true;
      TTYVTDisallocate = true;
    };
  };
}
