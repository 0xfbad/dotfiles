_: {
  flake.homeModules.ssh = _: {
    services.ssh-agent.enable = true;
    programs.ssh = {
      enable = true;
      enableDefaultConfig = false;
      matchBlocks."*" = {
        addKeysToAgent = "yes";
        compression = true;
        extraOptions = {
          ControlMaster = "auto";
          ControlPath = "~/.ssh/master-%C";
          ControlPersist = "600";
        };
      };
    };
  };
}
