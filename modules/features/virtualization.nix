_: {
  flake.nixosModules.virtualization = {pkgs, ...}: {
    virtualisation.docker.enable = true;
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
