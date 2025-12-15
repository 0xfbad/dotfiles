{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  # nix
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nixpkgs.config.allowUnfree = true;
  programs.nix-ld.enable = true;
  system.stateVersion = "24.11";

  # boot
  boot.loader.grub = {
    enable = true;
    device = "/dev/nvme0n1";
    useOSProber = true;
  };
  boot.kernelModules = [ "kvm-intel" "kvm-amd" ];
  boot.extraModprobeConfig = ''
    options kvm-intel nested=1
    options kvm-amd nested=1
  '';
  boot.plymouth = {
    enable = true;
    theme = "pixels";
    themePackages = [
      (pkgs.adi1090x-plymouth-themes.override { selected_themes = [ "pixels" ]; })
    ];
  };
  boot.consoleLogLevel = 3;
  boot.initrd.verbose = false;
  boot.kernelParams = [ "quiet" "splash" "udev.log_priority=3" ];

  # networking
  networking.hostName = "desktop";
  networking.networkmanager.enable = true;

  # locale
  time.timeZone = "America/Los_Angeles";
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  # display and desktop
  services.xserver.enable = true;
  services.xserver.xkb.layout = "us";
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;

  # nvidia
  hardware.graphics.enable = true;
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = false;
    powerManagement.finegrained = false;
    open = false;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.production;
  };

  # sudo
  security.sudo.extraConfig = "Defaults pwfeedback";

  # audio
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # virtualization
  virtualisation.docker.enable = true;
  virtualisation.libvirtd = {
    enable = true;
    qemu.swtpm.enable = true;
  };
  virtualisation.spiceUSBRedirection.enable = true;
  services.spice-vdagentd.enable = true;
  services.qemuGuest.enable = true;

  # services
  services.printing.enable = true;
  services.netbird.enable = true;

  # flatpak
  services.flatpak.enable = true;
  services.flatpak.packages = [
    "org.vinegarhq.Sober"
  ];

  # programs
  programs.firefox.enable = true;
  programs.steam.enable = true;
  programs.wireshark = {
    enable = true;
    package = pkgs.wireshark;
  };

  # shell
  programs.zsh.enable = true;
  users.defaultUserShell = pkgs.zsh;
  environment.shells = [ pkgs.zsh ];

  # default editor
  environment.variables.EDITOR = "hx";
  environment.variables.VISUAL = "hx";

  # system packages
  environment.systemPackages = with pkgs; [
    helix
    wget
    git
    grim

    # virtualization
    virt-manager
    virt-viewer
    qemu
    spice-gtk
    libvirt
    dnsmasq
    phodav
  ];

  # user
  users.users.fbad = {
    isNormalUser = true;
    description = "fbad";
    extraGroups = [ "networkmanager" "wheel" "libvirtd" "kvm" "wireshark" "docker" ];
    shell = pkgs.zsh;
  };
}
