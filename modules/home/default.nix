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
    # clobber a stale .hm-bak instead of failing the rebuild
    home-manager.overwriteBackup = true;
    home-manager.users.fbad = {
      imports = builtins.attrValues self.modules.homeManager;
      home.stateVersion = "24.11";
      # the manpage build pulls the full options doc eval into the closure
      manual.manpages.enable = false;
      # hm does not follow the nixpkgs release cycle
      home.enableNixpkgsReleaseCheck = false;
    };
  };
}
