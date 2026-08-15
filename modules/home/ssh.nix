_: {
  flake.modules.homeManager.ssh = _: {
    services.ssh-agent = {
      enable = true;
      defaultMaximumIdentityLifetime = 28800;
    };
    programs.ssh = {
      enable = true;
      enableDefaultConfig = false;
      includes = [ "~/.ssh/config.d/*" ];
      settings."*" = {
        AddKeysToAgent = "yes";
        SetEnv.TERM = "xterm-256color";
        ControlMaster = "auto"; # most goated feature of ssh btw
        ControlPath = "~/.ssh/master-%C";
        ControlPersist = "600";
        ServerAliveInterval = 60;
        ServerAliveCountMax = 3;
        # HashKnownHosts off otherwise it kills hostname completion
      };
    };
  };
}
