_: {
  flake.modules.nixos.yubikey = _: {
    # fido uaccess udev rules ship with systemd
    programs.yubikey-manager.enable = true;

    # the key has no touch led
    programs.yubikey-touch-detector.enable = true;
  };
}
