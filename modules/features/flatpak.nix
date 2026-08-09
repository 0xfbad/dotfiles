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
        # despite the readme auto.enable only drives the timer, activation reads onActivation
        auto = {
          enable = true;
          onCalendar = "daily";
        };
        # off so a switch never needs the network
        onActivation = false;
      };

      uninstallUnused = true;
    };
  };
}
