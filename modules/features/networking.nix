_: {
  flake.nixosModules.networking = {lib, ...}: {
    networking.networkmanager.enable = true;
    networking.networkmanager.dns = lib.mkForce "none";
    networking.nameservers = ["127.0.0.1" "::1"];

    # don't block boot waiting for network on a desktop
    systemd.network.wait-online.enable = false;
    systemd.services.NetworkManager-wait-online.enable = false;

    # don't drop network mid-rebuild (avoids killing SSH, breaking switches)
    systemd.services.NetworkManager.stopIfChanged = false;
    systemd.services.systemd-resolved.stopIfChanged = false;
  };
}
