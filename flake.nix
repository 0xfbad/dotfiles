{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    import-tree.url = "github:denful/import-tree";
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # upstream has no release branch, so pin the rev rather than track main
    nix-flatpak.url = "github:gmodena/nix-flatpak/20d42f0ee98c9fe9f85e8d1de474f1409ed10d05";
    nix-index-database = {
      url = "github:Mic92/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    wlctl = {
      url = "github:aashish-thapa/wlctl";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    niri = {
      # niri.cachix.org hits need our nixpkgs rev to match niri-flake, update both together
      url = "github:sodiboo/niri-flake";
      # build neutral, overlays.niri builds against our nixpkgs either way
      inputs.nixpkgs.follows = "nixpkgs";
    };
    lanzaboote = {
      url = "github:nix-community/lanzaboote/v1.1.0";
      inputs.nixpkgs.follows = "nixpkgs";
      # upstream only vendors it for its own devshell, follow so it drops out of the lock
      inputs.pre-commit.follows = "nixpkgs";
    };
    plasma-manager = {
      url = "github:nix-community/plasma-manager";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
    spicetify = {
      url = "github:Gerg-L/spicetify-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    llm-agents = {
      url = "github:numtide/llm-agents.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # main matches home-manager master, no follows since ports are cached against catppuccin pkgs
    catppuccin.url = "github:catppuccin/nix/main";
    # no nixpkgs follows and release tags only, both keep vicinae cachix hits
    vicinae.url = "github:vicinaehq/vicinae/v0.24.0";
    vicinae-extensions = {
      url = "github:vicinaehq/extensions";
      inputs.vicinae.follows = "vicinae";
    };
    # unofficial linux repack of codex desktop app
    codex-desktop-linux = {
      url = "github:ilysenko/codex-desktop-linux/8bc6bead687f719d9835c426b431f09f4acbc277";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # source only, no upstream flake, rebuilding it needs a fresh cargoHash
    ouch = {
      url = "github:ouch-org/ouch/384384286fa575975e088f14f71b5ccd039bedf4";
      flake = false;
    };
  };

  # bootstrap only, covers root nixos-install before nix.settings caches exist
  nixConfig = {
    extra-substituters = [
      "https://niri.cachix.org"
      "https://vicinae.cachix.org"
      "https://catppuccin.cachix.org"
    ];
    extra-trusted-public-keys = [
      "niri.cachix.org-1:Wv0OmO7PsuocRKzfDoJ3mulSl7Z6oezYhGhR+3W2964="
      "vicinae.cachix.org-1:1kDrfienkGHPYbkpNj1mWTr7Fm1+zcenzgTizIcI3oc="
      "catppuccin.cachix.org-1:noG/4HkbhJb+lUAdKrph6LaozJvAeEEZj4N732IysmU="
    ];
  };

  outputs = inputs: inputs.flake-parts.lib.mkFlake { inherit inputs; } (inputs.import-tree ./modules);
}
