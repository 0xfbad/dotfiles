{inputs, ...}: {
  perSystem = {pkgs, ...}: let
    treefmt = inputs.treefmt.lib.evalModule pkgs {
      projectRootFile = "flake.nix";
      programs.statix.enable = true;
      programs.alejandra.enable = true;
    };
  in {
    formatter = treefmt.config.build.wrapper;
    checks.formatting = treefmt.config.build.check inputs.self;
  };
}
