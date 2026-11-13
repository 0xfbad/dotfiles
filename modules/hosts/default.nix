{
  self,
  inputs,
  lib,
  ...
}:
{
  flake.modules.nixos.workstation.imports = with self.modules.nixos; [
    common
    niri
    greetd
    nvidia
    audio
    virtualization
    anonymity
    networking
    flatpak
    yubikey
    homeManager
  ];

  flake.nixosConfigurations = lib.genAttrs [ "desktop" "laptop" ] (
    host:
    inputs.nixpkgs.lib.nixosSystem {
      modules = [
        self.modules.nixos."${host}Configuration"
        { system.configurationRevision = self.rev or self.dirtyRev or null; }
      ];
    }
  );
}
