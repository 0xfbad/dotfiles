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
    home-manager.backupFileExtension = "hm-bak";
    home-manager.users.fbad = {lib, ...}: {
      imports = builtins.attrValues self.homeModules;
      # skip home-manager manpages, silences the options.json eval warning
      manual.manpages.enable = false;
      # hm doesnt follow same release cycle as nixpkgs
      home.enableNixpkgsReleaseCheck = false;
      # wipe stale hm backups before activation so they never block a rebuild
      home.activation.cleanupBackups = lib.hm.dag.entryBefore ["checkLinkTargets"] ''
        find /home/fbad -name "*.hm-bak" -delete 2>/dev/null || true
      '';
    };
  };
}
