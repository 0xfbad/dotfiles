_: {
  flake.homeModules.zellij = {
    pkgs,
    lib,
    ...
  }: let
    zellij-gc = pkgs.writeShellScriptBin "zellij-gc" (
      ''
        export PATH=${lib.makeBinPath [pkgs.zellij pkgs.iproute2 pkgs.procps pkgs.coreutils pkgs.gnugrep]}:$PATH
      ''
      + builtins.readFile ./zellij-gc.sh
    );
  in {
    home.packages = [zellij-gc];

    programs.zellij = {
      enable = true;
      settings = {
        theme = "catppuccin-mocha";
        default_layout = "compact";
        show_startup_tips = false;
        copy_on_select = true;
        pane_frames = false;
        # scrollback opens in helix
        scrollback_editor = "hx";
      };
    };

    systemd.user.services.zellij-gc = {
      Unit.Description = "Reap idle and exited zellij sessions";
      Service = {
        Type = "oneshot";
        ExecStart = "${zellij-gc}/bin/zellij-gc";
      };
    };

    systemd.user.timers.zellij-gc = {
      Unit.Description = "Periodically reap idle zellij sessions";
      Timer = {
        OnBootSec = "2min";
        OnUnitActiveSec = "5min";
      };
      Install.WantedBy = ["timers.target"];
    };
  };
}
