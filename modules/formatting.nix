{ inputs, ... }: {
  imports = [ inputs.flake-parts.flakeModules.partitions ];

  partitions.dev = {
    extraInputsFlake = ../dev;
    module.imports = [ ../dev/flake-module.nix ];
  };

  partitionedAttrs = {
    checks = "dev";
    devShells = "dev";
    formatter = "dev";
  };
}
