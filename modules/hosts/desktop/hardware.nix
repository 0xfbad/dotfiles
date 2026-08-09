_: {
  flake.modules.nixos.desktopHardware =
    {
      config,
      lib,
      modulesPath,
      ...
    }:
    {
      imports = [
        (modulesPath + "/installer/scan/not-detected.nix")
      ];

      # the rest of the generated list is already in boot.initrd.includeDefaultModules
      boot.initrd.availableKernelModules = [ "usb_storage" ];
      boot.kernelModules = [ "kvm-intel" ];

      fileSystems."/" = {
        device = "/dev/disk/by-uuid/0590fcd2-0dc0-41a0-8adf-5fe895c641c7";
        fsType = "ext4";
        options = [ "noatime" ];
      };

      nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
      hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
    };
}
