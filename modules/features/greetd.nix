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

    # nixpkgs commit 9128dd3 made the hyprland module wire UWSM to launch
    # the Hyprland binary directly, skipping start-hyprland which sets up
    # XDG_CURRENT_DESKTOP and portal integration. without it, screen sharing
    # and some electron apps break silently.
    programs.uwsm.waylandCompositors.hyprland = {
      prettyName = "Hyprland";
      comment = "Hyprland compositor managed by UWSM";
      binPath = "/run/current-system/sw/bin/start-hyprland";
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
