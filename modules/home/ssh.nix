_: {
  flake.homeModules.ssh = _: {
    services.ssh-agent.enable = true;
    programs.ssh = {
      enable = true;
      enableDefaultConfig = false;
      settings."*" = {
        AddKeysToAgent = "yes";
        Compression = true;
        ControlMaster = "auto";
        ControlPath = "~/.ssh/master-%C";
        ControlPersist = "600";
      };
    };
  };
}
