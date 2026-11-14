{
  # no nixpkgs, the partition inherits root inputs
  inputs = {
    treefmt.url = "github:numtide/treefmt-nix";
    treefmt.inputs.nixpkgs.follows = "";
  };

  outputs = _: { };
}
