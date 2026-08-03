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
      self.nixosModules.niri
      self.nixosModules.greetd
      self.nixosModules.nvidia
      self.nixosModules.audio
      self.nixosModules.virtualization
      self.nixosModules.anonymity
      self.nixosModules.networking
      self.nixosModules.flatpak
      self.nixosModules.yubikey
      self.nixosModules.homeManager
    ];

    nixpkgs.overlays = [
      (final: prev: {wlctl = inputs.wlctl.packages.${final.stdenv.hostPlatform.system}.default;})
    ];

    networking.hostName = "laptop";

    services.upower.enable = true;
    services.power-profiles-daemon.enable = true;

    # intel iGPU VA-API for hardware video encode/decode
    hardware.graphics.extraPackages = with pkgs; [intel-media-driver];

    # render on the dGPU so the external skips the iGPU to dGPU copy
    home-manager.users.fbad.programs.niri.settings.debug.render-drm-device = "/dev/dri/by-path/pci-0000:01:00.0-render";

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
