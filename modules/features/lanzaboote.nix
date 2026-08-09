{ inputs, ... }: {
  flake.modules.nixos.lanzaboote = { pkgs, ... }: {
    imports = [
      inputs.lanzaboote.nixosModules.lanzaboote
    ];

    # lzbt installs through boot.loader.external, which flips systemd-boot.enable off itself
    boot.lanzaboote = {
      enable = true;
      pkiBundle = "/var/lib/sbctl";
      configurationLimit = 5;
      # the systemd-boot bootCounting.tries default, carried across the move
      bootCounting.initialTries = 3;
      # keys generate on next boot not at switch, allowUnsigned follows so the unsigned pass boots
      autoGenerateKeys.enable = true;
    };

    # sbctl reads /etc/sbctl/sbctl.conf, which the module writes
    environment.systemPackages = [ pkgs.sbctl ];

    # to turn on secure boot, reboot into the bios, keep secure boot enabled, select Reset to Setup Mode, do not select Clear All Keys, it removes the dbx
    # then run sudo sbctl enroll-keys --microsoft and check with bootctl status, without --microsoft the machine can fail to boot
  };
}
