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
      # on the desktop, get the nvme path from /dev/disk/by-id and set it here, nvme0n1 follows enumeration order and can point grub at the wrong disk
      device = "/dev/nvme0n1";
      configurationLimit = 5;
      # hidden still honors esc, f4 and shift during the timeout, timeout 0 does not
      timeoutStyle = "hidden";
    };
    boot.loader.timeout = 1;
  };
}
