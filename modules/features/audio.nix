_: {
  flake.modules.nixos.audio = { pkgs, ... }: {
    environment.systemPackages = with pkgs; [
      sox_ng # maintained sox fork, installs as sox/play/rec/soxi
      pwvucontrol # pipewire volume control gui
    ];
    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      wireplumber.extraConfig."11-bluetooth-policy"."wireplumber.settings"."bluetooth.autoswitch-to-headset-profile" =
        false;
    };
  };
}
