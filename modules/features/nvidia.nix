_: {
  flake.modules.nixos.nvidia = _: {
    # misleading name but still required for kernel module loading on wayland
    services.xserver.videoDrivers = [ "nvidia" ];

    # videoDrivers only force loads modules under xserver, wayland needs these explicit
    boot.kernelModules = [
      "nvidia"
      "nvidia_modeset"
      "nvidia_drm"
    ];

    environment.sessionVariables = {
      LIBVA_DRIVER_NAME = "nvidia";
    };

    hardware = {
      graphics.enable = true;
      nvidia = {
        branch = "production";
        open = true;
      };
      # cdi passthrough for docker, run containers with --device=nvidia.com/gpu=all
      nvidia-container-toolkit.enable = true;
    };
  };
}
