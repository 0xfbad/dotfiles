{ inputs, ... }: {
  flake.modules.nixos.lanzaboote = { pkgs, ... }: {
    imports = [
      inputs.lanzaboote.nixosModules.lanzaboote
    ];

    # boot.loader.external defaults systemd-boot.enable to false, no mkForce needed
    boot.lanzaboote = {
      enable = true;
      pkiBundle = "/var/lib/sbctl";
      configurationLimit = 5;
      bootCounting.initialTries = 3;
      # enabling this defaults allowUnsigned to true
      autoGenerateKeys.enable = false;
    };

    # to enroll keys, put secure boot in setup mode from the bios, do not clear all keys, then run sbctl enroll-keys --microsoft, without --microsoft the machine can fail to boot
    environment.systemPackages = [ pkgs.sbctl ];
  };
}
