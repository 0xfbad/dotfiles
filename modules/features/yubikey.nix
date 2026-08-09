_: {
  flake.modules.nixos.yubikey = _: {
    # fido hidraw uaccess already comes from the systemd 60-fido-id.rules and 70-uaccess.rules
    programs.yubikey-manager.enable = true;

    # desktop notification on touch requests from browser fido2, the security key has no led
    programs.yubikey-touch-detector.enable = true;
  };
}
