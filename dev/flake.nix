{
  # no nixpkgs on purpose, the partition inherits root inputs, declaring one shadows them
  inputs = {
    treefmt.url = "github:numtide/treefmt-nix";
  };

  # the flake-parts module lives in ./flake-module.nix, this flake only carries inputs
  outputs = _: { };
}
