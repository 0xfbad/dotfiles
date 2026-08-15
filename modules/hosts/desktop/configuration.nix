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

    powerManagement.cpuFreqGovernor = "performance";

    # the firefox rdd sandbox cannot open nvidia device nodes, vaapi decode falls back to software
    environment.sessionVariables.MOZ_DISABLE_RDD_SANDBOX = "1";

    boot.loader.grub = {
      enable = true;
      # TODO this name is enumeration order, repoint at the path from ls -l /dev/disk/by-id | grep nvme
      device = "/dev/nvme0n1";
      configurationLimit = 5;
      # hidden still honours esc/f4/shift during the timeout, menu at timeout 0 does not
      timeoutStyle = "hidden";
    };
    boot.loader.timeout = 1;
  };
}
