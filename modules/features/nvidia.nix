_: {
  flake.nixosModules.nvidia = {
    config,
    pkgs,
    ...
  }: {
    hardware.graphics.enable = true;
    # misleading name but still required for kernel module loading on wayland
    services.xserver.videoDrivers = ["nvidia"];

    environment.sessionVariables = {
      LIBVA_DRIVER_NAME = "nvidia";
      GBM_BACKEND = "nvidia-drm";
      __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    };
    hardware.nvidia = {
      modesetting.enable = true;
      powerManagement.enable = false;
      powerManagement.finegrained = false;
      # open kernel modules work for turing+ (20xx and above)
      open = true;
      nvidiaSettings = true;
      package = config.boot.kernelPackages.nvidiaPackages.production;
    };
  };
}
