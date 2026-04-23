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
    nix.registry = builtins.mapAttrs (_: flake: {inherit flake;}) inputs;
    nix.nixPath = ["nixpkgs=flake:nixpkgs"];

    nixpkgs.config.allowUnfree = true;

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
      path = [pkgs.gawk pkgs.pciutils pkgs.coreutils pkgs.util-linux];
      script = ''
        parse_gpu() {
          echo "$1" | gawk '{
            name = ""
            s = $0
            while (match(s, /\[([^\]]+)\]/, a)) {
              if (a[1] != "AMD/ATI" && a[1] !~ /^[0-9a-f]{4}:[0-9a-f]{4}$/)
                name = a[1]
              s = substr(s, RSTART + RLENGTH)
            }
            if (name == "") {
              sub(/.*: /, "")
              sub(/ \(rev.*\)/, "")
              if (match($0, /(GeForce|Quadro|Tesla|Radeon|Arc |UHD|Iris|HD Graphics).*/, a))
                name = a[0]
              else
                name = $0
            }
            if (name ~ /^GeForce|^Quadro|^Tesla/) name = "NVIDIA " name
            else if (name ~ /^Radeon/) name = "AMD " name
            else if (name ~ /^Arc |^UHD |^Iris|^HD Graphics/) name = "Intel " name
            else if ($0 ~ /NVIDIA/) name = "NVIDIA " name
            else if ($0 ~ /AMD|ATI/) name = "AMD " name
            else if ($0 ~ /Intel/) name = "Intel " name
            print name
          }'
        }

        os=$(. /etc/os-release && echo "$PRETTY_NAME")
        kernel=$(uname -r)
        arch=$(uname -m)
        cpu=$(awk -F: '/model name/ {gsub(/^ +/, "", $2); print $2; exit}' /proc/cpuinfo)
        cores=$(nproc)
        mem=$(awk '/MemTotal/ {printf "%.0f GB", $2/1024/1024}' /proc/meminfo)
        discrete_line=$(lspci | awk '/VGA|3D/ && !/^00/ {print; exit}')
        integrated_line=$(lspci | awk '/VGA|3D/ && /^00/ {print; exit}')
        discrete=$(parse_gpu "$discrete_line")
        integrated=$(parse_gpu "$integrated_line")
        if [ -n "$discrete" ] && [ -n "$integrated" ]; then
          gpu="$discrete & integrated graphics"
        elif [ -n "$discrete" ]; then
          gpu="$discrete"
        else
          gpu="$integrated"
        fi
        disk=$(df -h / | awk 'NR==2 {print $2 " total, " $4 " free"}')
        gen=$(readlink /nix/var/nix/profiles/system | sed 's/system-\([0-9]*\)-.*/\1/')

        cat > /etc/issue <<EOF
        $os | $arch | $kernel
        $cpu ($cores cores) | $mem RAM
        $gpu
        Disk: $disk | Gen: $gen
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
        JustWorksRepairing = "always";
        Privacy = "off";
      };
      LE = {
        MinConnectionInterval = 7;
        MaxConnectionInterval = 9;
        ConnectionLatency = 0;
      };
    };
    hardware.bluetooth.input = {
      General = {
        IdleTimeout = 0;
        UserspaceHID = true;
        ClassicBondedOnly = false;
      };
    };
    # blueman tray disabled, using bluetui instead
    services.blueman.enable = false;

    # disable ERTM for bluetooth keyboards
    boot.extraModprobeConfig = ''
      options bluetooth disable_ertm=1
    '';

    # xbox controller support (current controller is firmware 5.09 which has issues with reconnecting after it sleeps, update it when u can via xbox accessories app)
    hardware.xpadneo.enable = true;
    # force xpadneo binding on systemd 258+
    services.udev.extraRules = ''
      ACTION=="bind", SUBSYSTEM=="hid", DRIVER!="xpadneo", KERNEL=="0005:045E:*:*02FD.*|*:02E0.*|*:0B05.*|*:0B13.*|*:0B20.*|*:0B22.*", ATTR{driver/unbind}="%k", ATTR{[drivers/hid:xpadneo]bind}="%k"
      ACTION!="remove", DRIVERS=="xpadneo", SUBSYSTEM=="input", TAG+="uaccess"
      ACTION!="remove", DRIVERS=="xpadneo", SUBSYSTEM=="hidraw", MODE:="0000", TAG-="uaccess"
    '';

    # services
    services.printing = {
      enable = true;
      drivers = [pkgs.brlaser];
    };
    services.netbird.enable = true;
    services.udisks2.enable = true; # needed for dolphin to discover and mount removable drives

    # programs
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

    # hunspell dictionaries for thunderbird/firefox spell check
    environment.variables.DICPATH = "/run/current-system/sw/share/hunspell";

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
      helix # modal text editor, tree-sitter built in
      wget # download files from the web
      git # version control
      grim # screenshot tool for Wayland
      polkit_gnome # authentication agent for privilege escalation dialogs
      hunspellDicts.en_US-large
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
