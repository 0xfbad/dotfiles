{ self, inputs, ... }: {
  flake.modules.nixos.laptopConfiguration =
    {
      pkgs,
      lib,
      ...
    }:
    {
      imports = [
        inputs.windows-vm-stealth.nixosModules.default
        self.modules.nixos.laptopHardware
        self.modules.nixos.lanzaboote
        self.modules.nixos.workstation
      ];

      networking.hostName = "laptop";

      services.windows-vm-stealth = {
        enable = true;
        users = [ "fbad" ];
      };

      system.stateVersion = "24.11";

      services.upower = {
        enable = true;
        # HybridSleep still drains
        criticalPowerAction = "Hibernate";
        percentageLow = 15;
        percentageCritical = 5;
        percentageAction = 3;
      };

      # when the monitors sleep logind stops seeing the dock and suspends on the closed lid
      services.logind.settings.Login.HandleLidSwitchExternalPower = "ignore";

      services.power-profiles-daemon.enable = true;
      services.thermald.enable = true;
      services.fwupd.enable = true;
      hardware.nvidia.dynamicBoost.enable = true;
      # resume dies without it
      hardware.nvidia.powerManagement.enable = true;

      # ppd never switches profiles on its own
      services.udev.extraRules = ''
        # usb pd ports are power_supply devices too
        SUBSYSTEM=="power_supply", ATTR{type}=="Mains", ATTR{online}=="0", TAG+="systemd", ENV{SYSTEMD_WANTS}+="power-profile-battery.service"
        # RUN would fire at coldplug before ppd is up
        SUBSYSTEM=="power_supply", ATTR{type}=="Mains", ATTR{online}=="1", TAG+="systemd", ENV{SYSTEMD_WANTS}+="power-profile-ac.service"
      '';
      systemd.services =
        let
          onPowerChange = description: script: {
            inherit description script;
            requires = [ "power-profiles-daemon.service" ];
            after = [ "power-profiles-daemon.service" ];
            path = [ pkgs.power-profiles-daemon ];
            serviceConfig = {
              Type = "oneshot";
              RuntimeDirectory = "power-profile";
              RuntimeDirectoryPreserve = true;
            };
          };
        in
        {
          power-profile-battery = onPowerChange "Drop to power-saver on battery" ''
            current=$(powerprofilesctl get)
            if [ "$current" = power-saver ]; then exit 0; fi

            echo "$current" > "$RUNTIME_DIRECTORY/previous"
            powerprofilesctl set power-saver
          '';
          power-profile-ac = onPowerChange "Restore the power profile on ac" ''
            if [ "$(powerprofilesctl get)" != power-saver ]; then exit 0; fi

            previous=$(cat "$RUNTIME_DIRECTORY/previous" 2>/dev/null || echo balanced)
            rm -f "$RUNTIME_DIRECTORY/previous"
            powerprofilesctl set "$previous"
          '';
        };

      hardware.graphics.extraPackages = with pkgs; [
        intel-media-driver
        vpl-gpu-rt
        intel-compute-runtime
      ];
      # nvidia.nix pins this globally and nvidia-vaapi-driver only decodes
      environment.sessionVariables.LIBVA_DRIVER_NAME = lib.mkForce "iHD";

      home-manager.users.fbad.programs.niri.settings = {
        # externals skip the igpu to dgpu copy
        debug.render-drm-device = "/dev/dri/by-path/pci-0000:01:00.0-render";
        outputs."LG Electronics LG ULTRAGEAR+ 301NTMX55883" = {
          mode = {
            width = 2560;
            height = 1440;
            refresh = 239.970;
          };
          scale = 1.0;
          transform.rotation = 90;
          position = {
            x = -1440;
            y = -560;
          };
        };
        outputs."LG Electronics LG ULTRAGEAR+ 407NTWG1S097" = {
          mode = {
            width = 3440;
            height = 1440;
            refresh = 240.085;
          };
          scale = 1.0;
          position = {
            x = 0;
            y = 0;
          };
        };
      };

      boot.loader.efi.canTouchEfiVariables = true;
      boot.loader.timeout = 0;
      # dell ucsi errors spam the greeter tty
      boot.consoleLogLevel = 3;
    };
}
