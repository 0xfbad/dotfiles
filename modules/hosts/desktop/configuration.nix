{ self, ... }: {
  flake.modules.nixos.desktopConfiguration = _: {
    imports = [
      self.modules.nixos.desktopHardware
      self.modules.nixos.workstation
    ];

    networking.hostName = "desktop";

    system.stateVersion = "24.11";

    powerManagement.cpuFreqGovernor = "performance";

    # nvidia vaapi decode fails inside the rdd sandbox
    environment.sessionVariables.MOZ_DISABLE_RDD_SANDBOX = "1";

    boot.loader.grub = {
      enable = true;
      # TODO use the /dev/disk/by-id path, nvme0n1 is enumeration order
      device = "/dev/nvme0n1";
      configurationLimit = 5;
      # hidden still honors esc/f4/shift during the timeout, timeout 0 does not
      timeoutStyle = "hidden";
    };
    boot.loader.timeout = 1;
  };
}
