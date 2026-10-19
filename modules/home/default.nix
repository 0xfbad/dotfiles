{
  self,
  inputs,
  ...
}:
{
  flake.modules.nixos.homeManager = { ... }: {
    imports = [
      inputs.home-manager.nixosModules.home-manager
    ];

    home-manager.useGlobalPkgs = true;
    home-manager.useUserPackages = true;
    home-manager.backupFileExtension = "hm-bak";
    home-manager.overwriteBackup = true;
    home-manager.users.fbad = {
      imports = builtins.attrValues self.modules.homeManager;
      home.stateVersion = "24.11";
      manual.manpages.enable = false;
      home.enableNixpkgsReleaseCheck = false;
    };
  };
}
