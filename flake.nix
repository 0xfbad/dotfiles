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
    nix-flatpak.url = "github:gmodena/nix-flatpak/v0.8.0";
    nix-index-database = {
      url = "github:Mic92/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    wlctl = {
      url = "github:aashish-thapa/wlctl";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    niri = {
      # cache hits need nixpkgs and niri-flake bumped together
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    lanzaboote = {
      url = "github:nix-community/lanzaboote/v1.2.0";
      inputs.nixpkgs.follows = "nixpkgs";
      # devshell only upstream, following drops it from the lock
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
      inputs.flake-parts.follows = "flake-parts";
    };
    # main pairs with home-manager master, no follows keeps the cache hits
    catppuccin.url = "github:catppuccin/nix/main";
    # no follows and release tags only, both keep the cache hits
    vicinae.url = "github:vicinaehq/vicinae/v0.30.0";
    vicinae-extensions = {
      url = "github:vicinaehq/extensions";
      inputs.vicinae.follows = "vicinae";
      # read for lib only, extensions build with the vicinae nixpkgs
      inputs.nixpkgs.follows = "nixpkgs";
    };
    windows-vm-stealth = {
      url = "path:/home/fbad/windows-sandbox";
    };
  };

  # for nixos-install, before nix.settings exists
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
