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
      virt-manager
      qemu
      spice-gtk
      libvirt
      dnsmasq
      phodav
    ];
  };
}
