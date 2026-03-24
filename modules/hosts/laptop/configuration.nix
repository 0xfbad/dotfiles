{
  self,
  inputs,
  ...
}: {
  flake.nixosModules.laptopConfiguration = {pkgs, ...}: {
    imports = [
      self.nixosModules.laptopHardware
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

    nixpkgs.config.allowUnfree = true;
    nixpkgs.overlays = [inputs.nix-matlab.overlay];

    networking.hostName = "laptop";

    boot.loader.systemd-boot.enable = true;
    boot.loader.systemd-boot.configurationLimit = 5;
    boot.loader.efi.canTouchEfiVariables = true;
    boot.loader.timeout = 0;
    boot.initrd.systemd.enable = true;
    boot.kernelModules = ["kvm-intel"];
    boot.extraModprobeConfig = ''
      options kvm-intel nested=1
    '';
  };
}
