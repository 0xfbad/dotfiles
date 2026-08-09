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

      # the rest of the generated list is already in boot.initrd.includeDefaultModules
      boot.initrd.availableKernelModules = [
        # must load early or it tears down the firmware dp tunnel to the dock
        "thunderbolt"
        "uas"
        "rtsx_pci_sdmmc"
        # systemd-cryptsetup wants the tpm driver in stage 1 for the tpm2 unlock
        "tpm-crb"
        "tpm-tis"
      ];
      # early kms i915 so the luks prompt clones onto the dock monitor over the tb4 hdmi tunnel
      boot.initrd.kernelModules = [ "i915" ];
      boot.kernelModules = [ "kvm-intel" ];

      boot.initrd.luks.devices."luks-989d2a80-dc9d-4fb3-8f7f-ccaf01168651" = {
        device = "/dev/disk/by-uuid/989d2a80-dc9d-4fb3-8f7f-ccaf01168651";
        # dm-crypt drops TRIM without this, so services.fstrim does nothing
        allowDiscards = true;
        bypassWorkqueues = true;
        # after secure boot is on, run sudo systemd-cryptenroll --tpm2-device=auto --tpm2-with-pin=yes, the passphrase slot stays
        crypttabExtraOpts = [ "tpm2-device=auto" ];
      };

      # systemd stage 1 wants the mapper path, not the UUID of the ext4 inside it
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

      # no resume= on purpose, systemd-sleep records HibernateLocation in efi and stage 1 reads it back
      swapDevices = [
        {
          # if resume is empty, set boot.resumeDevice to the mapper path and get resume_offset from filefrag -v /swapfile
          device = "/swapfile";
          # sized for a full ram hibernation image, zram keeps priority 5
          size = 32 * 1024;
        }
      ];

      nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
      hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
    };
}
