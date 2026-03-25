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
    programs.nix-ld.enable = true;
    programs.nix-index-database.comma.enable = true;
    system.stateVersion = "24.11";

    # boot (shared settings, bootloader is host-specific)
    # logs scroll normally, greetd covers them when it starts

    # generate /etc/issue with system specs at boot
    systemd.services.generate-issue = {
      description = "Generate /etc/issue with system specs";
      wantedBy = ["multi-user.target"];
      before = ["greetd.service"];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      path = [pkgs.gawk pkgs.pciutils pkgs.iproute2 pkgs.coreutils pkgs.util-linux];
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
    services.blueman.enable = true;

    # disable ERTM for bluetooth keyboards
    boot.extraModprobeConfig = ''
      options bluetooth disable_ertm=1
    '';

    # services
    services.printing.enable = true;
    services.netbird.enable = true;

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
    environment.shells = [pkgs.zsh];

    # editor
    environment.variables.EDITOR = "hx";
    environment.variables.VISUAL = "hx";

    # wayland env vars for electron apps
    environment.sessionVariables.NIXOS_OZONE_WL = "1";

    # system packages
    environment.systemPackages = with pkgs; [
      helix
      wget
      git
      grim
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
