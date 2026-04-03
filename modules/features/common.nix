{
  self,
  inputs,
  ...
}: {
  flake.nixosModules.common = {
    config,
    pkgs,
    lib,
    ...
  }: {
    imports = [
      inputs.nix-index-database.nixosModules.nix-index
    ];

    # nix
    nix.settings.warn-dirty = false;
    nix.settings.download-attempts = 5;
    nix.settings.connect-timeout = 10;
    nix.settings.stalled-download-timeout = 30;
    programs.nix-ld.enable = true;
    programs.nix-index-database.comma.enable = true;
    programs.nh = {
      enable = true;
      clean.enable = true;
      clean.extraArgs = "--keep-since 7d --keep 3";
      flake = "/home/fbad/dotfiles";
    };
    system.stateVersion = "24.11";

    # keep build deps in store so nix develop doesn't re-download after GC
    nix.settings.keep-outputs = true;
    nix.settings.keep-env-derivations = true;

    # auto GC when disk gets tight instead of failing mid-build
    nix.settings.min-free = 5368709120; # 5 GB
    nix.settings.max-free = 21474836480; # 20 GB

    # kill channels and the global flake registry, pin all inputs to local store
    # so nix run nixpkgs#, nix run home-manager#, etc. resolve instantly from lockfile
    nix.settings.flake-registry = "";
    nix.channel.enable = false;
    nix.registry = builtins.mapAttrs (_: flake: {flake = flake;}) inputs;
    nix.nixPath = ["nixpkgs=flake:nixpkgs"];

    # strip default packages (perl, rsync, strace)
    environment.defaultPackages = [];

    # boot (shared settings, bootloader is host-specific)
    # logs scroll normally, greetd covers them when it starts

    systemd.services.generate-issue = {
      description = "Generate /etc/issue with system specs";
      wantedBy = ["multi-user.target"];
      before = ["greetd.service"];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      path = [pkgs.gawk pkgs.pciutils pkgs.iproute2 pkgs.coreutils pkgs.util-linux pkgs.hostname];
      script = ''
                os=$(. /etc/os-release && echo "$PRETTY_NAME")
                kernel=$(uname -r)
                arch=$(uname -m)
                cpu=$(awk -F: '/model name/ {gsub(/^ +/, "", $2); print $2; exit}' /proc/cpuinfo)
                cores=$(nproc)
                mem=$(awk '/MemTotal/ {printf "%.0f GB", $2/1024/1024}' /proc/meminfo)
                gpu=$(lspci | awk -F: '/VGA|3D/ {gsub(/^ +/, "", $3); print $3; exit}')
                disk=$(df -h / | awk 'NR==2 {print $2 " total, " $4 " free"}')
                ip=$(ip -4 -br addr show | awk '/UP/ {gsub(/\/.*/, "", $3); print $3; exit}')
                host=$(hostname)

                cat > /etc/issue <<EOF
        $os | $arch | $kernel
        $cpu ($cores cores) | $mem RAM
        $gpu
        Disk: $disk | IP: ''${ip:-no network}
        EOF
      '';
    };
    environment.etc."issue".enable = false;

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

    # sudo
    security.sudo.extraConfig = "Defaults pwfeedback";

    security.pam.services.hyprlock = {};

    # bluetooth (needs to be up before greetd for wireless keyboards)
    hardware.bluetooth.enable = true;
    hardware.bluetooth.powerOnBoot = true;
    hardware.bluetooth.settings = {
      General = {
        FastConnectable = true;
      };
    };
    hardware.bluetooth.input = {
      General = {
        IdleTimeout = 0;
      };
    };
    # blueman tray disabled, using bluetui instead
    services.blueman.enable = false;

    # disable ERTM for bluetooth keyboards
    boot.extraModprobeConfig = ''
      options bluetooth disable_ertm=1
    '';

    # services
    services.printing.enable = true;
    services.netbird.enable = true;

    # programs
    programs.firefox = {
      enable = true;
      policies = {
        DisableTelemetry = true;
        DisableFirefoxStudies = true;
        DisablePocket = true;
        DisableFirefoxAccounts = true;
        DisableProfileImport = true;
        DontCheckDefaultBrowser = true;
        EnableTrackingProtection = {
          Value = true;
          Locked = true;
          Cryptomining = true;
          Fingerprinting = true;
        };
        FirefoxHome = {
          Search = true;
          TopSites = false;
          SponsoredTopSites = false;
          Highlights = false;
          Pocket = false;
          SponsoredPocket = false;
          Snippets = false;
          Locked = true;
        };
        NoDefaultBookmarks = true;
        DisplayBookmarksToolbar = "always";
        DisplayMenuBar = "default-off";
        ShowHomeButton = true;
        ExtensionSettings = {
          "uBlock0@raymondhill.net" = {
            install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
            installation_mode = "force_installed";
            default_area = "navbar";
          };
          "{446900e4-71c2-419f-a6a7-df9c091e268b}" = {
            install_url = "https://addons.mozilla.org/firefox/downloads/latest/bitwarden-password-manager/latest.xpi";
            installation_mode = "force_installed";
            default_area = "navbar";
          };
          "addon@darkreader.org" = {
            install_url = "https://addons.mozilla.org/firefox/downloads/latest/darkreader/latest.xpi";
            installation_mode = "force_installed";
            default_area = "navbar";
          };
          "firefox@tampermonkey.net" = {
            install_url = "https://addons.mozilla.org/firefox/downloads/latest/tampermonkey/latest.xpi";
            installation_mode = "force_installed";
            default_area = "navbar";
          };
          "myallychou@gmail.com" = {
            install_url = "https://addons.mozilla.org/firefox/downloads/latest/youtube-recommended-videos/latest.xpi";
            installation_mode = "force_installed";
            default_area = "menupanel";
          };
          "{a6c4a591-f1b2-4f03-b3ff-767e5bedf4e7}" = {
            install_url = "https://addons.mozilla.org/firefox/downloads/latest/user-agent-string-switcher/latest.xpi";
            installation_mode = "force_installed";
            default_area = "navbar";
          };
          "{DEBA3021-9876-4702-89BA-42D095339A0A}" = {
            install_url = "https://addons.mozilla.org/firefox/downloads/latest/disable-page-visibility/latest.xpi";
            installation_mode = "force_installed";
            default_area = "menupanel";
          };
          "{7343f7d1-e6ef-4d8a-8449-d4c18850f559}" = {
            install_url = "https://addons.mozilla.org/firefox/downloads/latest/clipboard2file/latest.xpi";
            installation_mode = "force_installed";
            default_area = "menupanel";
          };
        };
      };
    };
    programs.steam = {
      enable = true;
      protontricks.enable = true;
      extraCompatPackages = with pkgs; [proton-ge-bin];
      extraPackages = with pkgs; [gamescope];
    };
    programs.gamemode.enable = true;
    programs.gamescope = {
      enable = true;
      capSysNice = true;
    };
    programs.wireshark = {
      enable = true;
      package = pkgs.wireshark;
    };

    # dolphin file manager needs this for "open with" outside plasma
    environment.etc."xdg/menus/applications.menu".source = "${pkgs.kdePackages.plasma-workspace}/etc/xdg/menus/plasma-applications.menu";

    # shell
    programs.zsh.enable = true;
    users.defaultUserShell = pkgs.zsh;
    environment.shells = [pkgs.zsh];

    # editor
    environment.variables.EDITOR = "hx";
    environment.variables.VISUAL = "hx";
    environment.variables.SUDO_EDITOR = "hx";

    # wayland env vars for electron apps
    environment.sessionVariables.NIXOS_OZONE_WL = "1";

    # systemd manager settings
    systemd.settings.Manager = {
      DefaultTimeoutStopSec = "5s";
      DefaultOOMPolicy = "stop";
      StatusUnitFormat = "combined";
      RuntimeWatchdogSec = "15"; # seconds before hard-reset on hang
      RebootWatchdogSec = "30"; # seconds to wait for clean reboot
      KexecWatchdogSec = "60"; # seconds to wait for kexec
    };

    # systemd-oomd acts on memory pressure before the kernel OOM killer fires
    # without the slice settings it's a no-op, these tell it what to actually watch
    systemd.oomd = {
      enable = true;
      enableRootSlice = true;
      enableSystemSlice = true;
      enableUserSlices = true;
    };

    # gpt-auto-generator is redundant on NixOS (declarative fileSystems)
    # and causes spurious "Failed to dissect" errors during rebuild
    systemd.suppressedSystemUnits = ["systemd-gpt-auto-generator.service"];

    # caps lock as escape (TTY, xwayland)
    services.xserver.xkb.options = "caps:escape";
    console.useXkbConfig = true;

    # ollama
    services.ollama.enable = true;

    # fonts
    fonts.fontconfig.defaultFonts = {
      sansSerif = ["Noto Sans" "Noto Color Emoji"];
      serif = ["Noto Serif" "Noto Color Emoji"];
      monospace = ["JetBrainsMono Nerd Font" "Noto Color Emoji"];
      emoji = ["Noto Color Emoji"];
    };

    # system packages
    environment.systemPackages = with pkgs; [
      helix
      wget
      git
      grim
      polkit_gnome
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
  };
}
