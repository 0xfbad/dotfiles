_: {
  flake.modules.homeManager.ssh =
    { pkgs, lib, ... }:
    let
      privateHosts = lib.concatStringsSep " " (
        [
          "10.*"
          "192.168.*"
          "*.local"
        ]
        ++ map (octet: "172.${toString octet}.*") (lib.range 16 31)
      );
    in
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
          # ssh-agent.service counts as started before its socket exists
          Restart = "on-failure";
          RestartSec = 1;
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
          ControlMaster = "auto";
          ControlPath = "~/.ssh/master-%C";
          ControlPersist = "600";
          ServerAliveInterval = 60;
          ServerAliveCountMax = 3;
          StrictHostKeyChecking = "accept-new";
          # no HashKnownHosts, it breaks hostname completion
        };

        # competition boxes get new keys on every reimage
        settings.${privateHosts} = {
          StrictHostKeyChecking = "no";
          UserKnownHostsFile = "/dev/null";
        };
      };
    };
}
