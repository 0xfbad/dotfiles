_: {
  flake.nixosModules.howdy = {
    config,
    lib,
    pkgs,
    ...
  }: {
    # remember to run:
    # sudo linux-enable-ir-emitter configure --no-gui
    # sudo howdy add
    # sudo howdy test (needs nix shell nixpkgs#xorg.xhost -c xhost +SI:localuser:root)
    # sudo howdy remove <label>
    services.linux-enable-ir-emitter.enable = true;

    services.howdy = {
      enable = true;
      control = "sufficient";
      settings.video = {
        device_path = "/dev/video2";
        dark_threshold = 50;
        certainty = 4.0;
      };
    };

    security.pam.services = {
      swaylock = {};
      # boltgolt/howdy#991: greetd worker crashes on pam_howdy
      greetd.howdy.enable = false;
    };

    security.pam.services.sudo.rules.auth = {
      howdy.order = config.security.pam.services.sudo.rules.auth.unix.order + 50;
      u2f.order = config.security.pam.services.sudo.rules.auth.unix.order + 100;
    };
    security.pam.services.login.rules.auth = {
      howdy.order = config.security.pam.services.login.rules.auth.unix.order + 50;
      u2f.order = config.security.pam.services.login.rules.auth.unix.order + 100;
    };
    security.pam.services.swaylock.rules.auth = {
      howdy.order = config.security.pam.services.swaylock.rules.auth.unix.order + 50;
      u2f.order = config.security.pam.services.swaylock.rules.auth.unix.order + 100;
    };
  };
}
