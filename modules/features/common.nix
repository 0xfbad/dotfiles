{ inputs, ... }:
let
  inherit (import ../../flake.nix) nixConfig;
in
{
  flake.modules.nixos.common =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      imports = [
        inputs.nix-index-database.nixosModules.nix-index
        inputs.catppuccin.nixosModules.catppuccin
      ];

      nix.package = pkgs.nixVersions.latest;
      nix.settings.experimental-features = [
        "nix-command"
        "flakes"
      ];

      nix.settings.warn-dirty = false;
      nix.settings.connect-timeout = 10;
      nix.settings.stalled-download-timeout = 30;
      # the 1 mib default stalls large nars into the timeout above
      nix.settings.download-buffer-size = 536870912;
      nix.settings.use-xdg-base-directories = true;

      # single user machine, untrusted users get flake nixConfig ignored with a warning
      nix.settings.trusted-users = [
        "root"
        "fbad"
      ];

      # mirrored from the flake bootstrap nixConfig so the lists cannot drift
      nix.settings.extra-substituters = nixConfig.extra-substituters;
      nix.settings.extra-trusted-public-keys = nixConfig.extra-trusted-public-keys;
      programs.nix-ld.enable = true;
      programs.nix-index-database.comma.enable = true;
      programs.nh = {
        enable = true;
        clean.enable = true;
        clean.extraArgs = "--keep-since 7d --keep 3";
        flake = "/home/fbad/dotfiles";
      };

      # keep build deps in store so nix develop does not redownload after gc
      nix.settings.keep-outputs = true;

      # auto gc when disk gets tight instead of failing during a build
      nix.settings.min-free = 5368709120; # 5 gb
      nix.settings.max-free = 21474836480; # 20 gb

      # keep-outputs pins every devShell closure, so dedupe the store on a timer
      nix.optimise.automatic = true;
      nix.optimise.dates = [ "weekly" ];

      # no channels or global flake registry, pin inputs so nix run x# resolves from the lockfile
      nix.settings.flake-registry = "";
      nix.channel.enable = false;
      # nixpkgs and NIX_PATH already come from nixpkgs.flake.setFlakeRegistry
      nix.registry = builtins.mapAttrs (_: flake: { inherit flake; }) (
        removeAttrs inputs [
          "self"
          "nixpkgs"
        ]
      );

      nixpkgs.overlays = [
        (final: _: { wlctl = inputs.wlctl.packages.${final.stdenv.hostPlatform.system}.default; })
      ];

      nixpkgs.config.allowUnfree = true;

      # temporary for winboat, find a better fix
      nixpkgs.config.permittedInsecurePackages = [ "electron-40.10.5" ];

      # drop the default perl, rsync, strace
      environment.defaultPackages = [ ];

      # bootloader is per host, no quiet boot, greetd covers the scrolling logs

      # obs virtual camera needs a loopback device, out of tree so it can hold back a kernel bump
      boot.extraModulePackages = [ config.boot.kernelPackages.v4l2loopback ];
      boot.kernelModules = [ "v4l2loopback" ];
      boot.extraModprobeConfig = ''
        options v4l2loopback devices=1 video_nr=1 card_label="OBS Virtual Camera" exclusive_caps=1
      '';

      systemd.services.generate-issue = {
        description = "Generate /etc/issue with system specs";
        wantedBy = [ "multi-user.target" ];
        before = [ "greetd.service" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        path = [
          pkgs.gawk
          pkgs.pciutils
          pkgs.coreutils
          pkgs.util-linux
        ];
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

      time.timeZone = "America/New_York";
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

      # recovery if polkitd breaks, su with the root password or boot an older generation
      security.sudo.enable = false;
      # privilege escalation without a setuid binary, run0 asks polkitd through the agent
      security.run0 = {
        enable = true;
        # keeps sudo working for scripts and the zsh double esc binding, -e -l -k error out
        sudo-shim.enable = true;
      };

      # rapl is root gated, the btop watts row stays hidden without these capabilities
      security.wrappers.btop = {
        # the override has to match modules/home/btop.nix or this builds a second closure
        source = "${pkgs.btop.override { cudaSupport = true; }}/bin/btop";
        capabilities = "cap_perfmon,cap_dac_read_search+ep";
        owner = "root";
        group = "root";
      };

      # tear down the session on logout so a stale niri socket does not block the next login
      services.logind.settings.Login.KillUserProcesses = true;

      # bluetooth needs to be up before greetd for wireless keyboards
      hardware.bluetooth.enable = true;
      hardware.bluetooth.settings = {
        General = {
          FastConnectable = true;
          # always allows silent bond replacement
          JustWorksRepairing = "confirm";
          # bluez gates the battery service behind this flag, the waybar battery tooltip reads it
          Experimental = true;
        };
        LE = {
          # xpadneo wants 8.75 to 11.25ms to match the controller 100hz protocol
          MinConnectionInterval = 7;
          MaxConnectionInterval = 9;
          ConnectionLatency = 0;
        };
      };
      hardware.bluetooth.input.General = {
        UserspaceHID = true;
        # ClassicBondedOnly = false fixes pad pairing but reopens cve-2023-45866
      };

      # firmware 5.09 drops reconnects after sleep, fix is the xbox accessories app then repairing
      hardware.xpadneo.enable = true;
      # nixpkgs xpadneo only runs modules_install, upstream 60-xpadneo.rules restored by hand
      services.udev.extraRules = ''
        # the two KERNEL== keys are anded by udev, merged into one they can never match a hid name
        ACTION=="bind", SUBSYSTEM=="hid", DRIVER!="xpadneo", KERNEL=="0005:045E:*", KERNEL=="*:02FD.*|*:02E0.*|*:0B05.*|*:0B13.*|*:0B20.*|*:0B22.*", ATTR{driver/unbind}="%k", ATTR{[drivers/hid:xpadneo]bind}="%k"
        ACTION=="bind", SUBSYSTEM=="hid", DRIVER!="xpadneo", KERNEL=="0005:0B05:1ABD.*", ATTR{driver/unbind}="%k", ATTR{[drivers/hid:xpadneo]bind}="%k"
        ACTION!="remove", DRIVERS=="xpadneo", SUBSYSTEM=="input", ENV{ID_INPUT_JOYSTICK}=="1", TAG+="uaccess", MODE="0664", ENV{LIBINPUT_IGNORE_DEVICE}="1"
        ACTION!="remove", DRIVERS=="xpadneo", SUBSYSTEM=="hidraw", MODE:="0000", TAG-="uaccess"
      '';

      services.printing = {
        enable = true;
        drivers = [ pkgs.brlaser ];
      };
      services.netbird = {
        enable = true;
        ui.enable = true;
      };
      services.udisks2.enable = true; # dolphin needs it to discover and mount removable drives

      # the caps lock osd needs this root side libinput watcher, home manager only runs the client
      systemd.packages = [ pkgs.swayosd ];
      systemd.services.swayosd-libinput-backend.wantedBy = [ "graphical.target" ];
      # the dbus policy lets root own the name the session server listens on
      services.dbus.packages = [ pkgs.swayosd ];

      programs.steam = {
        enable = true;
        protontricks.enable = true;
        extest.enable = true; # steam input needs x11 events translated to uinput under wayland
        extraCompatPackages = with pkgs; [ proton-ge-bin ];
        extraPackages = with pkgs; [ gamescope ];
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

      # dolphin needs this for open with outside plasma
      environment.etc."xdg/menus/applications.menu".source =
        "${pkgs.kdePackages.plasma-workspace}/etc/xdg/menus/plasma-applications.menu";

      programs.zsh.enable = true;
      users.defaultUserShell = pkgs.zsh;

      environment.variables.EDITOR = "hx";
      environment.variables.VISUAL = "hx";

      # hunspell dictionaries for thunderbird and firefox spell check
      environment.variables.DICPATH = "/run/current-system/sw/share/hunspell";

      # wayland env vars for electron apps
      environment.sessionVariables.NIXOS_OZONE_WL = "1";

      systemd.settings.Manager = {
        DefaultTimeoutStopSec = "5s";
        StatusUnitFormat = "combined";
        RuntimeWatchdogSec = "15"; # hard reset on hang
        RebootWatchdogSec = "30"; # wait for clean reboot
        KExecWatchdogSec = "60"; # wait for kexec
      };

      # oomd does nothing without slice settings, these tell it what to watch
      systemd.oomd = {
        enableRootSlice = true;
        enableSystemSlice = true;
        enableUserSlices = true;
      };

      # oomd has nothing to reclaim without swap, neither host has a swap partition
      zramSwap.enable = true;

      # the kernel watchdog ejects a misbehaving sched_ext scheduler back to eevdf
      services.scx.enable = true;
      # latency first and hybrid core aware
      services.scx.scheduler = "scx_lavd";

      # redundant with declarative fileSystems, and it logs spurious dissect errors during rebuild
      systemd.generators.systemd-gpt-auto-generator = "/dev/null";

      services.xserver.xkb.options = "caps:escape";
      console.useXkbConfig = true;

      # scoped enables matching modules/home/catppuccin.nix
      catppuccin = {
        enable = true;
        autoEnable = false;
        flavor = "mocha";
        # covers the bare vt before greetd, the emergency shell and early boot
        tty.enable = true;
      };

      # slot 0 paints the vt background, mocha base glows grey on oled so true black instead
      console.colors =
        let
          palette = (lib.importJSON "${config.catppuccin.sources.palette}/palette.json").mocha.colors;
          hex = name: lib.substring 1 6 palette.${name}.hex;
        in
        lib.mkForce (
          [ "000000" ]
          ++ map hex [
            "red"
            "green"
            "yellow"
            "blue"
            "pink"
            "teal"
            "subtext1"
            "surface2"
            "red"
            "green"
            "yellow"
            "blue"
            "pink"
            "teal"
            "subtext0"
          ]
        );

      # system level so defaultFonts resolves for every process, not just the fbad profile
      fonts.packages = with pkgs; [
        nerd-fonts.jetbrains-mono
        material-symbols
        noto-fonts
      ];

      fonts.fontconfig.defaultFonts = {
        sansSerif = [
          "Noto Sans"
          "Noto Color Emoji"
        ];
        serif = [
          "Noto Serif"
          "Noto Color Emoji"
        ];
        monospace = [
          "JetBrainsMono Nerd Font"
          "Noto Color Emoji"
        ];
        emoji = [ "Noto Color Emoji" ];
      };

      environment.systemPackages = with pkgs; [
        helix
        wget
        git
        grim
        kdePackages.kio-admin # polkitd only scans /run/current-system for its action file
        hunspellDicts.en_US-large
      ];

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

  # nix records accepted nixConfig here, preseeding it stops the prompt direnv hits on fresh evals
  flake.modules.homeManager.nix-trusted-settings = {
    # readonly symlink, trust answers for other flakes will not persist, transient y still works
    xdg.dataFile."nix/trusted-settings.json" = {
      force = true;
      text = builtins.toJSON (builtins.mapAttrs (_: value: { ${toString value} = true; }) nixConfig);
    };
  };
}
