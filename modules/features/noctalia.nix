{inputs, ...}: {
  perSystem = {pkgs, ...}: {
    packages.noctalia-shell = inputs.wrapper-modules.wrappers.noctalia-shell.wrap {
      inherit pkgs;
      env = {
        "NOCTALIA_CACHE_DIR" = "/tmp/noctalia-cache/";
      };
      # oled black theme
      colors = {
        mError = "#f38ba8";
        mHover = "#181818";
        mOnError = "#000000";
        mOnHover = "#cdd6f4";
        mOnPrimary = "#000000";
        mOnSecondary = "#000000";
        mOnSurface = "#cdd6f4";
        mOnSurfaceVariant = "#a6adc8";
        mOnTertiary = "#000000";
        mOutline = "#1e1e2e";
        mPrimary = "#cba6f7";
        mSecondary = "#f9e2af";
        mShadow = "#000000";
        mSurface = "#000000";
        mSurfaceVariant = "#0a0a0a";
        mTertiary = "#94e2d5";
      };
      settings = {
        appLauncher = {
          customLaunchPrefix = "";
          customLaunchPrefixEnabled = false;
          enableClipPreview = true;
          enableClipboardHistory = true;
          iconMode = "tabler";
          pinnedExecs = [];
          position = "center";
          showCategories = true;
          sortByMostUsed = true;
          terminalCommand = "wezterm -e";
          useApp2Unit = false;
          viewMode = "list";
        };
        audio = {
          cavaFrameRate = 30;
          externalMixer = "pwvucontrol || pavucontrol";
          mprisBlacklist = [];
          preferredPlayer = "";
          visualizerType = "linear";
          volumeOverdrive = false;
          volumeStep = 5;
        };
        bar = {
          capsuleOpacity = 1;
          density = "comfortable";
          exclusive = true;
          floating = false;
          marginHorizontal = 0.25;
          marginVertical = 0.25;
          monitors = [];
          outerCorners = false;
          position = "top";
          showCapsule = false;
          showOutline = false;
          transparent = false;
          widgets = {
            center = [
              {
                customFont = "";
                formatHorizontal = "HH:mm ddd, MMM dd";
                formatVertical = "HH mm - dd MM";
                id = "Clock";
                useCustomFont = false;
                usePrimaryColor = true;
              }
            ];
            left = [
              {
                colorizeDistroLogo = true;
                colorizeSystemIcon = "tertiary";
                customIconPath = "";
                enableColorization = true;
                id = "ControlCenter";
                useDistroLogo = true;
              }
              {
                characterCount = 2;
                colorizeIcons = false;
                enableScrollWheel = true;
                followFocusedScreen = false;
                hideUnoccupied = true;
                id = "Workspace";
                labelMode = "none";
                showApplications = false;
                showLabelsOnlyWhenOccupied = true;
              }
            ];
            right = [
              {
                hideWhenZero = false;
                id = "NotificationHistory";
                showUnreadBadge = true;
              }
              {
                displayMode = "alwaysHide";
                id = "Volume";
              }
              {
                displayMode = "alwaysHide";
                id = "Microphone";
              }
              {
                blacklist = [];
                colorizeIcons = false;
                drawerEnabled = true;
                hidePassive = false;
                id = "Tray";
                pinned = [];
              }
            ];
          };
        };
        brightness = {
          brightnessStep = 5;
          enableDdcSupport = false;
          enforceMinimum = true;
        };
        calendar = {
          cards = [
            {
              enabled = true;
              id = "calendar-header-card";
            }
            {
              enabled = true;
              id = "calendar-month-card";
            }
            {
              enabled = true;
              id = "timer-card";
            }
          ];
        };
        controlCenter = {
          cards = [
            {
              enabled = true;
              id = "profile-card";
            }
            {
              enabled = true;
              id = "shortcuts-card";
            }
            {
              enabled = true;
              id = "audio-card";
            }
            {
              enabled = true;
              id = "brightness-card";
            }
            {
              enabled = true;
              id = "media-sysmon-card";
            }
          ];
          position = "close_to_bar_button";
          shortcuts = {
            left = [
              {id = "WiFi";}
              {id = "Bluetooth";}
              {id = "ScreenRecorder";}
            ];
            right = [
              {id = "Notifications";}
            ];
          };
        };
        desktopWidgets = {
          enabled = false;
          gridSnap = false;
          monitorWidgets = [];
        };
        dock = {
          animationSpeed = 2;
          backgroundOpacity = 1;
          colorizeIcons = false;
          deadOpacity = 0.6;
          displayMode = "auto_hide";
          enabled = false;
          floatingRatio = 1;
          inactiveIndicators = false;
          monitors = [];
          onlySameOutput = true;
          pinnedApps = [];
          pinnedStatic = false;
          size = 1;
        };
        general = {
          allowPanelsOnScreenWithoutBar = true;
          animationDisabled = true;
          animationSpeed = 1;
          boxRadiusRatio = 1;
          compactLockScreen = false;
          dimmerOpacity = 0.15;
          enableShadows = false;
          forceBlackScreenCorners = false;
          iRadiusRatio = 1;
          language = "";
          lockOnSuspend = true;
          radiusRatio = 1;
          scaleRatio = 1;
          screenRadiusRatio = 1;
          shadowDirection = "bottom_right";
          shadowOffsetX = 2;
          shadowOffsetY = 3;
          showHibernateOnLockScreen = false;
          showScreenCorners = false;
          showSessionButtonsOnLockScreen = true;
        };
        hooks = {
          darkModeChange = "";
          enabled = false;
          performanceModeDisabled = "";
          performanceModeEnabled = "";
          screenLock = "";
          screenUnlock = "";
          wallpaperChange = "";
        };
        location = {
          name = "Santa Cruz";
          analogClockInCalendar = false;
          firstDayOfWeek = -1;
          showCalendarEvents = true;
          showCalendarWeather = true;
          showWeekNumberInCalendar = false;
          use12hourFormat = false;
          useFahrenheit = true;
          weatherEnabled = true;
          weatherShowEffects = true;
        };
        network = {wifiEnabled = true;};
        nightLight = {
          autoSchedule = true;
          dayTemp = "6500";
          enabled = false;
          forced = false;
          manualSunrise = "06:30";
          manualSunset = "18:30";
          nightTemp = "4000";
        };
        notifications = {
          backgroundOpacity = 1;
          criticalUrgencyDuration = 15;
          enableKeyboardLayoutToast = true;
          enabled = true;
          location = "top_right";
          lowUrgencyDuration = 8;
          monitors = [];
          normalUrgencyDuration = 8;
          overlayLayer = true;
          respectExpireTimeout = false;
          sounds = {
            criticalSoundFile = "";
            enabled = false;
            excludedApps = "discord,firefox,chrome,chromium,edge";
            lowSoundFile = "";
            normalSoundFile = "";
            separateSounds = false;
            volume = 0.5;
          };
        };
        osd = {
          autoHideMs = 3000;
          backgroundOpacity = 1;
          enabled = true;
          enabledTypes = [0 1 2 4];
          location = "bottom";
          monitors = [];
          overlayLayer = true;
        };
        screenRecorder = {
          audioCodec = "opus";
          audioSource = "default_output";
          colorRange = "limited";
          directory = "/home/fbad/Videos";
          frameRate = 60;
          quality = "very_high";
          showCursor = true;
          videoCodec = "h264";
          videoSource = "portal";
        };
        sessionMenu = {
          countdownDuration = 10000;
          enableCountdown = true;
          largeButtonsStyle = false;
          position = "center";
          powerOptions = [
            {
              action = "lock";
              command = "";
              countdownEnabled = true;
              enabled = true;
            }
            {
              action = "suspend";
              command = "";
              countdownEnabled = true;
              enabled = true;
            }
            {
              action = "reboot";
              command = "";
              countdownEnabled = true;
              enabled = true;
            }
            {
              action = "logout";
              command = "";
              countdownEnabled = true;
              enabled = true;
            }
            {
              action = "shutdown";
              command = "";
              countdownEnabled = true;
              enabled = true;
            }
          ];
          showHeader = true;
        };
        settingsVersion = 32;
        systemMonitor = {
          cpuCriticalThreshold = 90;
          cpuPollingInterval = 3000;
          cpuWarningThreshold = 80;
          criticalColor = "";
          diskCriticalThreshold = 90;
          diskPollingInterval = 3000;
          diskWarningThreshold = 80;
          enableDgpuMonitoring = false;
          gpuCriticalThreshold = 90;
          gpuPollingInterval = 3000;
          gpuWarningThreshold = 80;
          memCriticalThreshold = 90;
          memPollingInterval = 3000;
          memWarningThreshold = 80;
          networkPollingInterval = 3000;
          tempCriticalThreshold = 90;
          tempPollingInterval = 3000;
          tempWarningThreshold = 80;
          useCustomColors = false;
          warningColor = "";
        };
        templates = {
          alacritty = false;
          cava = false;
          code = false;
          discord = false;
          emacs = false;
          enableUserTemplates = false;
          foot = false;
          fuzzel = false;
          ghostty = false;
          gtk = false;
          helix = false;
          hyprland = false;
          kcolorscheme = false;
          kitty = false;
          mango = false;
          niri = false;
          pywalfox = false;
          qt = false;
          spicetify = false;
          telegram = false;
          vicinae = false;
          walker = false;
          wezterm = false;
          yazi = false;
          zed = false;
        };
        ui = {
          bluetoothDetailsViewMode = "grid";
          bluetoothHideUnnamedDevices = false;
          fontDefault = "Sans Serif";
          fontDefaultScale = 1;
          fontFixed = "JetBrainsMono Nerd Font";
          fontFixedScale = 1;
          panelBackgroundOpacity = 1;
          panelsAttachedToBar = true;
          settingsPanelMode = "attached";
          tooltipsEnabled = true;
          wifiDetailsViewMode = "grid";
        };
        wallpaper = {
          enabled = false;
        };
      };
    };
  };
}
