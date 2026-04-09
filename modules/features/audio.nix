_: {
  flake.nixosModules.audio = {pkgs, ...}: {
    environment.systemPackages = with pkgs; [
      sox # audio processing CLI, record/convert/trim/apply effects
      pwvucontrol # PipeWire volume control GUI
    ];
    services.pulseaudio.enable = false;
    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };
  };
}
