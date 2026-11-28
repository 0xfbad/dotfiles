{ inputs, ... }: {
  flake.modules.nixos.flatpak = { ... }: {
    imports = [
      inputs.nix-flatpak.nixosModules.nix-flatpak
    ];

    services.flatpak = {
      enable = true;
      packages = [
        "org.vinegarhq.Sober"
        "io.github.unknownskl.greenlight"
      ];

      update = {
        auto = {
          enable = true;
          onCalendar = "daily";
        };
        onActivation = false;
      };

      uninstallUnused = true;
    };
  };
}
