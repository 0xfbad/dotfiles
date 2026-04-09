_: {
  flake.nixosModules.virtualization = {pkgs, ...}: {
    virtualisation.docker.enable = true;
    virtualisation.docker.daemon.settings = {
      log-driver = "json-file";
      log-opts = {
        max-size = "10m";
        max-file = "3";
      };
    };
    virtualisation.libvirtd = {
      enable = true;
      qemu.swtpm.enable = true;
    };
    virtualisation.spiceUSBRedirection.enable = true;
    services.spice-vdagentd.enable = true;
    services.qemuGuest.enable = true;

    environment.systemPackages = with pkgs; [
      virt-manager # GUI for managing KVM/QEMU virtual machines
      qemu # machine emulator and virtualizer
      spice-gtk # SPICE client for VM display and USB redirection
      libvirt # virtualization API and management daemon
      dnsmasq # DNS/DHCP server for VM networking
      phodav # WebDAV server for SPICE folder sharing
      winboat # Windows VM management
    ];
  };
}
