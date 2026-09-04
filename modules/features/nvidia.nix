_: {
  flake.modules.nixos.nvidia = { config, pkgs, ... }: {
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
        # 610 difr prefetch deadlocks nvkms, open-gpu-kernel-modules #1289, drop once a release carries pr 1286
        package = config.boot.kernelPackages.nvidiaPackages.mkDriver {
          version = "595.99.02";
          sha256_64bit = "sha256-6HR3lYv3YwcFSTJL1a1slI66btIQ5EAFs+/4SUD24ew=";
          sha256_aarch64 = "sha256-CCqHZTN2KNOZ4yZp2rDcuRJp9pHfRw47k4m4dWnS/2w=";
          openSha256 = "sha256-T36x/jx8yQ8l3LFp1rZIrTfcSwbGy8YSAvXOUSptpb4=";
          settingsSha256 = "sha256-GYCcnxfKPrTCrsmd25sMyzfC5cqJQJx0c31haooyTYM=";
          persistencedSha256 = "sha256-VyKtF/HdHPQrHHK6opSO69M72LmnGZtauuchj9uuje8=";
          patchesOpen = [
            (pkgs.fetchpatch {
              url = "https://github.com/NVIDIA/open-gpu-kernel-modules/commit/d7bfec267d5f18320a19fc0759c99ad969ae305f.patch";
              hash = "sha256-EzEQNc1cV3QDI0G2tbI8cGKh82yom6ol4hBN4UYhZAo=";
            })
            (pkgs.fetchpatch {
              url = "https://github.com/NVIDIA/open-gpu-kernel-modules/commit/937af596675ca8ee381db35750b581cac978b59f.patch";
              hash = "sha256-Tc/P3XdOIFw5ZAuL4yhzlPcbVw1FDUXAW4+2JKdWJcw=";
            })
          ];
        };
        open = true;
      };
      # cdi passthrough for docker, run containers with --device=nvidia.com/gpu=all
      nvidia-container-toolkit.enable = true;
    };
  };
}
