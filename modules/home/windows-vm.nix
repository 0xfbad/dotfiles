_: {
  flake.homeModules.windows-vm = {
    pkgs,
    lib,
    ...
  }: let
    windowsVm = pkgs.writeShellApplication {
      name = "windows-vm";
      runtimeInputs = with pkgs; [
        docker-compose
        freerdp
        gum
        jq
        libnotify
        coreutils
        gnugrep
        gnused
        gawk
      ];
      text = ''
        COMPOSE_FILE="$HOME/.config/windows/docker-compose.yml"

        install_vm() {
          if [[ ! -e /dev/kvm ]]; then
            echo "KVM not available, enable virtualization in BIOS"
            exit 1
          fi

          mkdir -p "$HOME/.windows" "$HOME/.config/windows" "$HOME/Windows"

          TOTAL_RAM_GB=$(awk 'NR==1 {printf "%d", $2/1024/1024}' /proc/meminfo)
          TOTAL_CORES=$(nproc)
          echo "System: ''${TOTAL_RAM_GB}G RAM, $TOTAL_CORES cores"
          echo ""

          RAM_OPTIONS=""
          for size in 2 4 8 16 32 64; do
            if (( size <= TOTAL_RAM_GB )); then
              RAM_OPTIONS="$RAM_OPTIONS ''${size}G"
            fi
          done
          # shellcheck disable=SC2086
          SELECTED_RAM=$(echo $RAM_OPTIONS | tr ' ' '\n' | gum choose --selected="4G" --header="RAM allocation") || { echo "Cancelled"; exit 1; }

          SELECTED_CORES=$(gum input --placeholder="1-$TOTAL_CORES" --value="2" --header="CPU cores" --char-limit=2) || { echo "Cancelled"; exit 1; }
          if ! [[ $SELECTED_CORES =~ ^[0-9]+$ ]] || (( SELECTED_CORES < 1 )) || (( SELECTED_CORES > TOTAL_CORES )); then
            echo "Invalid, defaulting to 2"
            SELECTED_CORES=2
          fi

          AVAILABLE_SPACE=$(df "$HOME" | awk 'NR==2 {print int($4/1024/1024)}')
          MAX_DISK_GB=$((AVAILABLE_SPACE - 10))
          if (( MAX_DISK_GB < 32 )); then
            echo "Not enough disk space (need 42G min, have ''${AVAILABLE_SPACE}G)"
            exit 1
          fi

          DISK_OPTIONS=""
          for size in 32 64 128 256 512; do
            if (( size <= MAX_DISK_GB )); then
              DISK_OPTIONS="$DISK_OPTIONS ''${size}G"
            fi
          done
          DEFAULT_DISK="64G"
          echo "$DISK_OPTIONS" | grep -q "64G" || DEFAULT_DISK="32G"
          # shellcheck disable=SC2086
          SELECTED_DISK=$(echo $DISK_OPTIONS | tr ' ' '\n' | gum choose --selected="$DEFAULT_DISK" --header="Disk size (64G+ recommended)") || { echo "Cancelled"; exit 1; }

          USERNAME=$(gum input --placeholder="default: docker" --header="Windows username") || { echo "Cancelled"; exit 1; }
          [[ -z $USERNAME ]] && USERNAME="docker"
          PASSWORD=$(gum input --placeholder="default: admin" --password --header="Windows password") || { echo "Cancelled"; exit 1; }
          [[ -z $PASSWORD ]] && PASSWORD="admin"

          echo ""
          gum style --border normal --padding "1 2" --align left --bold \
            "Windows VM" "" \
            "RAM:      $SELECTED_RAM" \
            "CPU:      $SELECTED_CORES cores" \
            "Disk:     $SELECTED_DISK" \
            "User:     $USERNAME"
          echo ""
          gum confirm "Proceed?" || { echo "Cancelled"; exit 1; }

          TZ=$(timedatectl show -p Timezone --value 2>/dev/null || echo UTC)

          cat > "$COMPOSE_FILE" << EOF
        services:
          windows:
            image: dockurr/windows
            container_name: windows-vm
            environment:
              VERSION: "11"
              RAM_SIZE: "$SELECTED_RAM"
              CPU_CORES: "$SELECTED_CORES"
              DISK_SIZE: "$SELECTED_DISK"
              USERNAME: "$USERNAME"
              PASSWORD: "$PASSWORD"
              TZ: "$TZ"
              ARGUMENTS: "-rtc base=localtime,clock=host,driftfix=slew"
            devices:
              - /dev/kvm
              - /dev/net/tun
            cap_add:
              - NET_ADMIN
            ports:
              - 127.0.0.1:8006:8006
              - 127.0.0.1:3389:3389/tcp
              - 127.0.0.1:3389:3389/udp
            volumes:
              - $HOME/.windows:/storage
              - $HOME/Windows:/shared
            restart: unless-stopped
            stop_grace_period: 2m
        EOF

          echo ""
          echo "Starting Windows VM (this downloads a Windows 11 image, might take a while)"
          if ! docker-compose -f "$COMPOSE_FILE" up -d 2>&1; then
            echo "Failed to start, check docker is running and you're in the docker group"
            exit 1
          fi

          echo ""
          echo "VM installing in background"
          echo "Monitor at http://127.0.0.1:8006"
          echo ""
          echo "Once Windows finishes installing: windows-vm launch"
        }

        launch_vm() {
          KEEP_ALIVE=false
          [[ "''${1:-}" = "--keep-alive" || "''${1:-}" = "-k" ]] && KEEP_ALIVE=true

          if [[ ! -f $COMPOSE_FILE ]]; then
            echo "Not configured, run: windows-vm install"
            exit 1
          fi

          WIN_USER=$(grep "USERNAME:" "$COMPOSE_FILE" | sed 's/.*USERNAME: "\(.*\)"/\1/')
          WIN_PASS=$(grep "PASSWORD:" "$COMPOSE_FILE" | sed 's/.*PASSWORD: "\(.*\)"/\1/')
          [[ -z ''${WIN_USER:-} ]] && WIN_USER="docker"
          [[ -z ''${WIN_PASS:-} ]] && WIN_PASS="admin"

          CONTAINER_STATUS=$(docker inspect --format='{{.State.Status}}' windows-vm 2>/dev/null || true)

          if [[ "$CONTAINER_STATUS" != "running" ]]; then
            notify-send -a "windows-vm" "Windows VM" "Starting, 15-30 seconds" -t 15000
            if ! docker-compose -f "$COMPOSE_FILE" up -d 2>&1; then
              notify-send -a "windows-vm" -u critical "Windows VM" "Failed to start"
              exit 1
            fi

            echo "Waiting for VM to boot..."
            WAIT=0
            until docker logs windows-vm 2>&1 | grep -qi "windows started successfully"; do
              sleep 2
              WAIT=$((WAIT + 1))
              if (( WAIT > 60 )); then
                echo "Timeout after 2 minutes"
                echo "If this is the first boot, Windows is still installing"
                echo "Check progress at http://127.0.0.1:8006"
                exit 1
              fi
            done
          fi

          RDP_SCALE=""
          if command -v hyprctl &> /dev/null; then
            SCALE_PCT=$(hyprctl monitors -j 2>/dev/null | jq -r '.[] | select(.focused == true) | .scale' 2>/dev/null | awk '{print int($1 * 100)}') || SCALE_PCT=100
            if (( SCALE_PCT >= 170 )); then
              RDP_SCALE="/scale:180"
            elif (( SCALE_PCT >= 130 )); then
              RDP_SCALE="/scale:140"
            fi
          fi

          notify-send -a "windows-vm" "Windows VM" "Connecting" -t 3000

          # shellcheck disable=SC2086
          xfreerdp /u:"$WIN_USER" /p:"$WIN_PASS" /v:127.0.0.1:3389 \
            -grab-keyboard /sound /microphone /clipboard /cert:ignore \
            /title:"Windows VM" /dynamic-resolution /gfx:AVC444 \
            /floatbar:sticky:off,default:visible,show:fullscreen \
            $RDP_SCALE || true

          if [[ $KEEP_ALIVE = "false" ]]; then
            docker-compose -f "$COMPOSE_FILE" down
          fi
        }

        stop_vm() {
          [[ ! -f $COMPOSE_FILE ]] && { echo "Not configured"; exit 1; }
          docker-compose -f "$COMPOSE_FILE" down
        }

        remove_vm() {
          gum confirm --default=false "Remove Windows VM and all data?" || { echo "Cancelled"; exit 1; }
          docker-compose -f "$COMPOSE_FILE" down 2>/dev/null || true
          docker rmi dockurr/windows 2>/dev/null || true
          rm -rf "$HOME/.config/windows" "$HOME/.windows"
          echo "Removed (~/Windows shared folder kept)"
        }

        status_vm() {
          if [[ ! -f $COMPOSE_FILE ]]; then
            echo "Not configured, run: windows-vm install"
            exit 1
          fi
          STATUS=$(docker inspect --format='{{.State.Status}}' windows-vm 2>/dev/null || echo "not found")
          if [[ $STATUS = "running" ]]; then
            echo "Running"
            echo "  Web: http://127.0.0.1:8006"
            echo "  RDP: port 3389"
          else
            echo "Status: $STATUS"
          fi
        }

        case "''${1:-help}" in
          install)       install_vm ;;
          launch|start)  launch_vm "''${2:-}" ;;
          stop|down)     stop_vm ;;
          remove)        remove_vm ;;
          status)        status_vm ;;
          help|--help|-h)
            echo "Usage: windows-vm <command>"
            echo ""
            echo "  install          configure and start Windows VM"
            echo "  launch [-k]      connect via RDP (--keep-alive to leave running)"
            echo "  stop             shut down"
            echo "  remove           delete VM and data"
            echo "  status           check state"
            ;;
          *) echo "Unknown: ''${1:-}" >&2; exit 1 ;;
        esac
      '';
    };
  in {
    home.packages = [windowsVm];

    xdg.desktopEntries.windows-vm = {
      name = "Windows";
      comment = "Launch Windows VM and connect with RDP";
      exec = "windows-vm launch";
      terminal = false;
      categories = ["System"];
    };
  };
}
