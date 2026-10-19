{
  # no nixpkgs, the partition inherits root inputs
  inputs = {
    treefmt.url = "github:numtide/treefmt-nix";
  };

  # inputs only, see flake-module.nix
  outputs = _: { };
}
