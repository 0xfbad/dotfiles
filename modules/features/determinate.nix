{ inputs, ... }: {
  flake.modules.nixos.determinate = {
    imports = [
      inputs.determinate.nixosModules.default
    ];

    # nh.clean owns gc, the determinate-nixd collector would race it
    environment.etc."determinate/config.json".text = builtins.toJSON {
      garbageCollector.strategy = "disabled";
    };
  };
}
