{inputs, ...}: {
  flake.nixosModules.flatpak = {...}: {
    imports = [
      inputs.nix-flatpak.nixosModules.nix-flatpak
    ];

    services.flatpak.enable = true;
    services.flatpak.packages = [
      "org.vinegarhq.Sober"
    ];
  };
}
