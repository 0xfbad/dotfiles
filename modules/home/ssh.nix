_: {
  flake.modules.homeManager.ssh =
    { pkgs, ... }:
    {
      services.ssh-agent.enable = true;

      systemd.user.services.ssh-add-keys = {
        Unit = {
          Description = "Add SSH keys to agent";
          After = [ "ssh-agent.service" ];
          Requires = [ "ssh-agent.service" ];
        };
        Service = {
          Type = "oneshot";
          RemainAfterExit = true;
          Environment = "SSH_AUTH_SOCK=%t/ssh-agent";
          ExecStart = "${pkgs.openssh}/bin/ssh-add %h/.ssh/id_ed25519";
        };
        Install.WantedBy = [ "default.target" ];
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
