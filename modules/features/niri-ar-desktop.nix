{ inputs, ... }: {
  flake.modules.nixos.niri-ar-desktop = {
    imports = [ inputs.niri-ar-desktop.nixosModules.default ];
    services.niri-ar-desktop.enable = true;
  };
}
