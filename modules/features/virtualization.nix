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
      autoPrune = {
        enable = true;
        dates = "weekly";
      };
    };

    virtualisation.libvirtd = {
      enable = true;
      onShutdown = "shutdown";
      # host arch only, no aarch64/riscv tcg emulation
      qemu.package = pkgs.qemu_kvm;
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

    # dnscrypt binds 172.17.0.1 before docker0 exists
    boot.kernel.sysctl."net.ipv4.ip_nonlocal_bind" = 1;

    programs.virt-manager.enable = true;
    programs.dconf.enable = true;

    environment.systemPackages = [ pkgs.winboat ];
  };
}
