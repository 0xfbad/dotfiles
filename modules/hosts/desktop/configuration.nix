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

    nixpkgs.config.allowUnfree = true;
    nixpkgs.overlays = [inputs.nix-matlab.overlay];

    networking.hostName = "desktop";

    boot.loader.grub = {
      enable = true;
      device = "/dev/nvme0n1";
      useOSProber = true;
      configurationLimit = 5;
    };
    boot.loader.timeout = 0;
    boot.kernelModules = ["kvm-intel" "kvm-amd"];
    boot.extraModprobeConfig = ''
      options kvm-intel nested=1
      options kvm-amd nested=1
    '';
  };
}
