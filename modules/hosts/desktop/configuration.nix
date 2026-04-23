{
  self,
  inputs,
  ...
}: {
  flake.nixosModules.desktopConfiguration = {pkgs, ...}: {
    imports = [
      self.nixosModules.desktopHardware
      self.nixosModules.determinate
      self.nixosModules.common
      self.nixosModules.hyprland
      self.nixosModules.greetd
      self.nixosModules.nvidia
      self.nixosModules.audio
      self.nixosModules.virtualization
      self.nixosModules.anonymity
      self.nixosModules.networking
      self.nixosModules.flatpak
      self.nixosModules.homeManager
    ];

    nixpkgs.overlays = [
      (final: prev: {wlctl = inputs.wlctl.packages.${final.stdenv.hostPlatform.system}.default;})
    ];

    networking.hostName = "desktop";

    # always run at max performance
    powerManagement.cpuFreqGovernor = "performance";

    boot.loader.grub = {
      enable = true;
      device = "/dev/nvme0n1";
      useOSProber = false;
      configurationLimit = 5;
    };
    boot.loader.timeout = 0;
    boot.kernelModules = ["kvm-intel"];
    boot.extraModprobeConfig = ''
      options kvm-intel nested=1
    '';
  };
}
