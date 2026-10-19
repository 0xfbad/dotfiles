_: {
  flake.modules.nixos.laptopHardware =
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

      # the rest of the generated list is in includeDefaultModules
      boot.initrd.availableKernelModules = [
        # loaded late it tears down the dp tunnel to the dock
        "thunderbolt"
        "uas"
        "rtsx_pci_sdmmc"
        "tpm-crb"
        "tpm-tis"
      ];
      # early kms so the luks prompt reaches the dock monitor
      boot.initrd.kernelModules = [ "i915" ];
      boot.kernelModules = [ "kvm-intel" ];

      boot.initrd.luks.devices."luks-989d2a80-dc9d-4fb3-8f7f-ccaf01168651" = {
        device = "/dev/disk/by-uuid/989d2a80-dc9d-4fb3-8f7f-ccaf01168651";
        allowDiscards = true;
        bypassWorkqueues = true;
        # enroll after secure boot with systemd-cryptenroll --tpm2-device=auto --tpm2-with-pin=yes
        crypttabExtraOpts = [ "tpm2-device=auto" ];
      };

      # systemd stage 1 wants the mapper path, not the ext4 uuid
      fileSystems."/" = {
        device = "/dev/mapper/luks-989d2a80-dc9d-4fb3-8f7f-ccaf01168651";
        fsType = "ext4";
        options = [ "noatime" ];
      };

      fileSystems."/boot" = {
        device = "/dev/disk/by-uuid/5FFA-EAAF";
        fsType = "vfat";
        options = [
          "fmask=0077"
          "dmask=0077"
        ];
      };

      # no resume= needed, systemd-sleep stores HibernateLocation in efi
      swapDevices = [
        {
          device = "/swapfile";
          # matches ram for hibernation
          size = 32 * 1024;
        }
      ];

      nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
      hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
    };
}
