{ inputs, ... }: {
  flake.modules.nixos.flatpak = { ... }: {
    imports = [
      inputs.nix-flatpak.nixosModules.nix-flatpak
    ];

    services.flatpak = {
      enable = true;
      packages = [
        "org.vinegarhq.Sober"
        "io.github.mandruis7.xbox-cloud-gaming-electron"
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
