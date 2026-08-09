{ inputs, ... }: {
  imports = [ inputs.flake-parts.flakeModules.partitions ];

  # formatter, linters and hooks live in ../dev with its own lock, rebuilds never resolve them
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
