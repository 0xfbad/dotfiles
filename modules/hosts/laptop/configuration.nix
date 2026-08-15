{ self, ... }: {
  flake.modules.nixos.laptopConfiguration =
    {
      pkgs,
      lib,
      ...
    }:
    {
      imports = [
        self.modules.nixos.laptopHardware
        self.modules.nixos.lanzaboote
        self.modules.nixos.common
        self.modules.nixos.niri
        self.modules.nixos.greetd
        self.modules.nixos.nvidia
        self.modules.nixos.audio
        self.modules.nixos.virtualization
        self.modules.nixos.anonymity
        self.modules.nixos.networking
        self.modules.nixos.flatpak
        self.modules.nixos.yubikey
        self.modules.nixos.homeManager
      ];

      networking.hostName = "laptop";

      services.upower = {
        enable = true;
        # the suspend half of HybridSleep still drains and at 3% there is nothing left to drain
        criticalPowerAction = "Hibernate";
        percentageLow = 15;
        percentageCritical = 5;
        percentageAction = 3;
      };

      services.power-profiles-daemon.enable = true;
      services.thermald.enable = true;
      services.fwupd.enable = true;
      hardware.nvidia.dynamicBoost.enable = true;

      # ppd holds no ac or battery policy of its own, that lives in gnome and kde daemons
      services.udev.extraRules = ''
        # type Mains only, usb pd ports are power_supply devices too and raced this at coldplug
        SUBSYSTEM=="power_supply", ATTR{type}=="Mains", ATTR{online}=="0", TAG+="systemd", ENV{SYSTEMD_WANTS}+="power-profile-battery.service"
        # SYSTEMD_WANTS not RUN, coldplug events fire before ppd is up
        SUBSYSTEM=="power_supply", ATTR{type}=="Mains", ATTR{online}=="1", TAG+="systemd", ENV{SYSTEMD_WANTS}+="power-profile-ac.service"
      '';
      systemd.services =
        let
          setProfile = profile: {
            description = "Set power profile to ${profile}";
            requires = [ "power-profiles-daemon.service" ];
            after = [ "power-profiles-daemon.service" ];
            serviceConfig = {
              Type = "oneshot";
              ExecStart = "${lib.getExe' pkgs.power-profiles-daemon "powerprofilesctl"} set ${profile}";
            };
          };
        in
        {
          power-profile-battery = setProfile "power-saver";
          power-profile-ac = setProfile "balanced";
        };

      hardware.graphics.extraPackages = with pkgs; [
        intel-media-driver
        vpl-gpu-rt
        intel-compute-runtime
      ];
      # nvidia.nix pins this globally and nvidia-vaapi-driver only decodes
      environment.sessionVariables.LIBVA_DRIVER_NAME = lib.mkForce "iHD";

      # render on the dGPU so the external skips the iGPU to dGPU copy
      home-manager.users.fbad.programs.niri.settings.debug.render-drm-device =
        "/dev/dri/by-path/pci-0000:01:00.0-render";

      # modules.nixos.lanzaboote owns the systemd-boot config, lzbt does the installing
      boot.loader.efi.canTouchEfiVariables = true;
      boot.loader.timeout = 0;
      # keep flaky dell ucsi errors off the greeter tty, crit and above still print
      boot.consoleLogLevel = 3;

      # default lts kernel on purpose, nvidia and out of tree modules lag newer kernels and block rebuilds
    };
}
