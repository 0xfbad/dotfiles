{
  self,
  inputs,
  ...
}: {
  flake.nixosModules.homeManager = {...}: {
    imports = [
      inputs.home-manager.nixosModules.home-manager
    ];

    home-manager.useGlobalPkgs = true;
    home-manager.useUserPackages = true;
    home-manager.backupFileExtension = "hm-backup";
    home-manager.users.fbad = {...}: {
      imports = builtins.attrValues self.homeModules;
    };
  };
}
