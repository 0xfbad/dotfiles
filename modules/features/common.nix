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
      nix.settings.download-buffer-size = 536870912; # the default buffer stalls large nars into the download timeout
      nix.settings.use-xdg-base-directories = true;

      nix.settings.trusted-users = [
        "root"
        "fbad"
      ];

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

      nix.settings.keep-outputs = true;

      nix.settings.min-free = 5368709120;
      nix.settings.max-free = 21474836480;

      nix.optimise.automatic = true;
      nix.optimise.dates = [ "weekly" ];

      nix.settings.flake-registry = "";
      nix.channel.enable = false;
      nix.registry = builtins.mapAttrs (_: flake: { inherit flake; }) (
        removeAttrs inputs [
          "self"
          "nixpkgs" # supplied by nixpkgs.flake.setFlakeRegistry
          "ouch" # not a flake
        ]
      );

      nixpkgs.overlays = [
        (final: _: { wlctl = inputs.wlctl.packages.${final.stdenv.hostPlatform.system}.default; })
      ];

      nixpkgs.config.allowUnfree = true;

      environment.defaultPackages = [ ];

      boot.kernelPackages = pkgs.linuxPackages_latest;

      boot.kernelParams = [ "split_lock_detect=off" ]; # kernel 7.2 panics on skb split locks even in warn mode
      boot.kernel.sysctl."kernel.panic" = 10;

      boot.extraModulePackages = [ config.boot.kernelPackages.v4l2loopback ];
      boot.kernelModules = [ "v4l2loopback" ];
      boot.extraModprobeConfig = ''
        options v4l2loopback devices=1 video_nr=1 card_label="Anker PowerConf C200" exclusive_caps=1
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

      security.sudo.enable = false; # if polkitd fails, use su or boot an older generation
      security.run0 = {
        enable = true;
        sudo-shim.enable = true; # the shim does not support -e -l -k
      };

      security.wrappers.btop = {
        source = "${pkgs.btop.override { cudaSupport = true; }}/bin/btop"; # must match modules/home/btop.nix to share its closure
        capabilities = "cap_perfmon,cap_dac_read_search+ep"; # rapl power readings require these capabilities
        owner = "fbad";
        group = "users";
        permissions = "u+rx"; # cap_dac_read_search permits reading any file
      };

      services.logind.settings.Login.KillUserProcesses = true; # stale niri sockets block the next login

      hardware.bluetooth.enable = true;
      hardware.bluetooth.settings = {
        General = {
          FastConnectable = true;
          JustWorksRepairing = "confirm"; # the always setting permits silent bond replacement
          Experimental = true; # the battery service requires this flag
        };
        LE = {
          MinConnectionInterval = 7; # the controller polls at 100 hz
          MaxConnectionInterval = 9;
          ConnectionLatency = 0;
        };
      };
      hardware.bluetooth.input.General = {
        UserspaceHID = true;
      };

      hardware.xpadneo.enable = true; # if reconnects fail after sleep, update firmware in the xbox accessories app and pair again
      services.udev.extraRules = # nixpkgs omits the upstream xpadneo device rules
        ''
          # udev combines separate KERNEL matches with logical and
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
      services.udisks2.enable = true;

      systemd.packages = [ pkgs.swayosd ];
      systemd.services.swayosd-libinput-backend.wantedBy = [ "graphical.target" ];
      environment.etc."xdg/swayosd/backend.toml".source =
        (pkgs.formats.toml { }).generate "swayosd-backend.toml"
          {
            input.ignore_caps_lock_key = true;
          };
      systemd.services.swayosd-libinput-backend.restartTriggers = [
        config.environment.etc."xdg/swayosd/backend.toml".source
      ];
      services.dbus.packages = [ pkgs.swayosd ];

      programs.steam = {
        enable = true;
        protontricks.enable = true;
        extest.enable = true;
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

      environment.etc."xdg/menus/applications.menu".source =
        "${pkgs.kdePackages.plasma-workspace}/etc/xdg/menus/plasma-applications.menu"; # dolphin requires this menu outside plasma

      programs.zsh.enable = true;
      users.defaultUserShell = pkgs.zsh;

      environment.variables.EDITOR = "hx";
      environment.variables.VISUAL = "hx";

      environment.variables.DICPATH = "/run/current-system/sw/share/hunspell";

      environment.sessionVariables.NIXOS_OZONE_WL = "1";

      systemd.settings.Manager = {
        DefaultTimeoutStopSec = "5s";
        StatusUnitFormat = "combined";
        RuntimeWatchdogSec = "15";
        RebootWatchdogSec = "30";
        KExecWatchdogSec = "60";
      };

      systemd.oomd = {
        enableRootSlice = true;
        enableSystemSlice = true;
        enableUserSlices = true;
      };

      zramSwap.enable = true;

      services.scx.enable = true;
      services.scx.scheduler = "scx_lavd";

      systemd.generators.systemd-gpt-auto-generator = "/dev/null"; # autodetection causes dissect errors with declarative mounts

      services.xserver.xkb.options = "caps:escape";
      console.useXkbConfig = true;

      catppuccin = {
        enable = true;
        autoEnable = false;
        flavor = "mocha";
        tty.enable = true;
      };

      console.colors =
        let
          palette = (lib.importJSON "${config.catppuccin.sources.palette}/palette.json").mocha.colors;
          hex = name: lib.substring 1 6 palette.${name}.hex;
        in
        lib.mkForce (
          [ "000000" ] # true black avoids gray backgrounds on oled
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

  flake.modules.homeManager.nix-trusted-settings = {
    xdg.dataFile."nix/trusted-settings.json" = {
      force = true;
      text = builtins.toJSON (builtins.mapAttrs (_: value: { ${toString value} = true; }) nixConfig); # trust answers for other flakes cannot persist through this readonly symlink
    };
  };
}
