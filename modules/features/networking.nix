_: {
  flake.nixosModules.networking = {lib, ...}: {
    networking.networkmanager.enable = true;
    networking.networkmanager.dns = lib.mkForce "none";
    networking.nameservers = ["127.0.0.1" "::1"];
  };
}
