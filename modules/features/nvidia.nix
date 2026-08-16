_: {
  flake.modules.nixos.nvidia = { config, ... }: {
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
        # 595.91.07 open deadlocks on resume, see open-gpu-kernel-modules #1246
        package = config.boot.kernelPackages.nvidiaPackages.mkDriver {
          version = "595.84";
          sha256_64bit = "sha256-mcQE5SExvye8ptoCaNzOPr7cenOrF0BxqZXPGmxeugY=";
          sha256_aarch64 = "sha256-GloNdDFfmXFVu4FAlNNk2qzqLOuw2N5CKatKkcSrQxk=";
          openSha256 = "sha256-pEmA2tUcOKwUPKy6N0QvS49Pdut4/7Phs/JhjdyBcNY=";
          settingsSha256 = "sha256-QrnBM+sdWO4GanO62rxpHmRrjYkYpl5RD6fIiHq4C4A=";
          persistencedSha256 = "sha256-50xYdgx7EEThbaMp4QS8GADbxj0mhBXh8QQN0tWMwRg=";
        };
        open = true;
      };
      # cdi passthrough for docker, run containers with --device=nvidia.com/gpu=all
      nvidia-container-toolkit.enable = true;
    };
  };
}
