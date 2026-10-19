{ self, ... }: {
  flake.modules.nixos.desktopConfiguration = _: {
    imports = [
      self.modules.nixos.desktopHardware
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
