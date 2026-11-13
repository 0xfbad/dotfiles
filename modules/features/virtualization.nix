_: {
  flake.modules.nixos.virtualization = { pkgs, ... }: {
    virtualisation.docker = {
      enable = true;
      logDriver = "json-file";
      daemon.settings = {
        live-restore = true;
        # without this docker strips loopback nameservers
        dns = [ "172.17.0.1" ];
        log-opts = {
          max-size = "10m";
          max-file = "3";
        };
      };
      autoPrune.enable = true;
    };

    virtualisation.libvirtd = {
      enable = true;
      onShutdown = "shutdown";
      shutdownTimeout = 30;
      parallelShutdown = 4; # 1 or 0 applies the timeout per guest in series
      qemu.swtpm.enable = true;
      qemu.vhostUserPackages = [ pkgs.virtiofsd ];
      nss.enable = true;
      nss.enableGuest = true;
    };
    virtualisation.spiceUSBRedirection.enable = true;

    networking.firewall.interfaces."docker0" = {
      allowedUDPPorts = [ 53 ];
      allowedTCPPorts = [ 53 ];
    };

    # compose creates a br-* bridge per project
    networking.firewall.extraInputRules = ''
      iifname "br-*" ip daddr 172.17.0.1 udp dport 53 accept
      iifname "br-*" ip daddr 172.17.0.1 tcp dport 53 accept
    '';

    # dnscrypt binds 172.17.0.1 before docker0 exists
    boot.kernel.sysctl."net.ipv4.ip_nonlocal_bind" = 1;

    programs.virt-manager.enable = true;
    programs.dconf.enable = true;

    environment.systemPackages = [ pkgs.winboat ];
  };
}
