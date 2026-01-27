{ config, pkgs, lib, ... }:

{
  # nix
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
  nix.settings.warn-dirty = false;
  nixpkgs.config.allowUnfree = true;
  programs.nix-ld.enable = true;
  system.stateVersion = "24.11";

  # boot (shared settings, bootloader is host-specific)
  boot.plymouth = {
    enable = true;
    theme = "pixels";
    themePackages = [
      (pkgs.adi1090x-plymouth-themes.override { selected_themes = [ "pixels" ]; })
    ];
  };
  boot.consoleLogLevel = 3;
  boot.initrd.verbose = false;
  boot.kernelParams = [
    "quiet"
    "splash"
    "udev.log_priority=3"
  ];

  # networking (hostName is host-specific)
  networking.networkmanager.enable = true;
  networking.networkmanager.dns = lib.mkForce "none";
  networking.nameservers = [ "127.0.0.1" "::1" ];

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
  services.xserver.excludePackages = [ pkgs.xterm ];
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;
  environment.gnome.excludePackages = with pkgs; [
    gnome-terminal # terminal emulator
    gnome-console # newer terminal emulator
    gnome-calculator # calculator
    gnome-connections # remote desktop client
    gnome-logs # systemd journal viewer
    seahorse # passwords and encryption keys manager
    geary # email client
    gnome-contacts # contacts manager
    gnome-calendar # calendar app
    gnome-music # music player
    totem # video player (old)
    showtime # video player (new)
    gnome-photos # photo manager
    snapshot # camera/webcam app
    gnome-maps # maps
    gnome-clocks # world clocks, alarms, timers
    simple-scan # document scanner
    baobab # disk usage analyzer
    gnome-tour # welcome/intro tour
    yelp # help docs viewer
    epiphany # web browser
    gnome-weather # weather app
    gnome-software # app store
    gnome-system-monitor # system monitor
  ];

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

  # anonymity
  services.i2pd = {
    enable = true;
    notransit = true;
    proto = {
      http.enable = true;
      httpProxy.enable = true;
      socksProxy.enable = true;
    };
  };
  services.tor = {
    enable = true;
    client.enable = true;
  };
  services.dnscrypt-proxy = {
    enable = true;
    settings = {
      listen_addresses = [ "127.0.0.1:53" "[::1]:53" ];

      max_clients = 250;

      dnscrypt_servers = false;
      doh_servers = true;
      odoh_servers = false;
      ipv4_servers = true;
      ipv6_servers = false;

      require_dnssec = true;
      require_nolog = true;
      require_nofilter = true;

      sources.public-resolvers = {
        urls = [
          "https://raw.githubusercontent.com/DNSCrypt/dnscrypt-resolvers/master/v3/public-resolvers.md"
          "https://download.dnscrypt.info/resolvers-list/v3/public-resolvers.md"
        ];
        cache_file = "public-resolvers.md";
        minisign_key = "RWQf6LRCGA9i53mlYecO4IzT51TGPpvWucNSCh1CBM0QTaLn73Y7GFO3";
      };
    };
  };
  services.resolved = {
    enable = true;
    settings.Resolve = {
      FallbackDNS = "127.0.0.1 ::1";
      LLMNR = false;
    };
  };

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
    extraGroups = [
      "networkmanager"
      "wheel"
      "libvirtd"
      "kvm"
      "wireshark"
      "docker"
    ];
    shell = pkgs.zsh;
  };
}
