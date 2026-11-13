{
  # no nixpkgs, the partition inherits root inputs
  inputs = {
    treefmt.url = "github:numtide/treefmt-nix";
    treefmt.inputs.nixpkgs.follows = "";
  };

  # inputs only, see flake-module.nix
  outputs = _: { };
}
