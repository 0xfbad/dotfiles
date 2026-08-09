{
  self,
  inputs,
  lib,
  ...
}:
{
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
