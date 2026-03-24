{inputs, ...}: {
  flake.nixosModules.determinate = {...}: {
    imports = [
      inputs.determinate.nixosModules.default
    ];
  };
}
