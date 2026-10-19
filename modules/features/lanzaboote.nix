{ inputs, ... }: {
  flake.modules.nixos.lanzaboote = { pkgs, ... }: {
    imports = [
      inputs.lanzaboote.nixosModules.lanzaboote
    ];

    # the module turns systemd-boot.enable off itself
    boot.lanzaboote = {
      enable = true;
      pkiBundle = "/var/lib/sbctl";
      configurationLimit = 5;
      bootCounting.initialTries = 3;
      # implies allowUnsigned
      autoGenerateKeys.enable = false;
    };

    environment.systemPackages = [ pkgs.sbctl ];

    # enroll via bios reset to setup mode, never clear all keys, then sbctl enroll-keys --microsoft or it may fail to boot
  };
}
