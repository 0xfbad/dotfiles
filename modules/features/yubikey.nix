_: {
  flake.nixosModules.yubikey = {pkgs, ...}: {
    # udev rules for Yubico devices (covers FIDO HID for the Security Key
    # and CCID/OTP if a YubiKey 5 ever joins the keyring)
    services.udev.packages = [pkgs.yubikey-personalization];

    environment.systemPackages = with pkgs; [
      yubikey-manager # ykman cli
      pam_u2f # provides pamu2fcfg for enrolling keys
    ];

    # touch the key as an alternative to typing the password
    # control = sufficient means a successful touch satisfies auth on its own,
    # failure or no key falls through to the normal password prompt
    security.pam.u2f = {
      enable = true;
      control = "sufficient";
      settings = {
        cue = true; # prompts "Please touch the device"
        interactive = true; # explicit prompt when no led is visible
        # kept in /etc instead of ~/.config so users can't add their own keys
        authfile = "/etc/u2f-mappings";
      };
    };

    security.pam.services = {
      sudo.u2fAuth = true;
      login.u2fAuth = true;
      swaylock.u2fAuth = true;
    };
  };
}
