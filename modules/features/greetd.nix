_: {
  flake.nixosModules.greetd = {
    pkgs,
    lib,
    ...
  }: {
    services.greetd = {
      enable = true;
      settings.default_session = {
        command = "${pkgs.tuigreet}/bin/tuigreet --time --remember-session --asterisks --issue --cmd 'uwsm start hyprland-uwsm.desktop'";
        user = "greeter";
      };
    };

    # register hyprland with uwsm properly
    programs.uwsm.waylandCompositors.hyprland = {
      prettyName = "Hyprland";
      comment = "Hyprland compositor managed by UWSM";
      binPath = "/run/current-system/sw/bin/Hyprland";
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
