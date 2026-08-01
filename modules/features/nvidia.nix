_: {
  flake.nixosModules.nvidia = {
    config,
    pkgs,
    ...
  }: {
    hardware.graphics.enable = true;
    # misleading name but still required for kernel module loading on wayland
    services.xserver.videoDrivers = ["nvidia"];

    # only force loads if services.xserver.enable is true, nvidia_drm never loads on wayland
    boot.kernelModules = ["nvidia" "nvidia_modeset" "nvidia_drm"];

    environment.sessionVariables = {
      LIBVA_DRIVER_NAME = "nvidia";
      GBM_BACKEND = "nvidia-drm";
      __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    };
    hardware.nvidia = {
      modesetting.enable = true;
      powerManagement.enable = true; # preserve vram across suspend so my laptop doesnt DIE when it suspends
      powerManagement.finegrained = false;
      open = true;
      nvidiaSettings = true;
      package = config.boot.kernelPackages.nvidiaPackages.production;
    };
  };
}
