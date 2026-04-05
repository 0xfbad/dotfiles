import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.SystemTray
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import Quickshell.Services.Mpris
import Quickshell.Services.Notifications
import Quickshell.Bluetooth

ShellRoot {
  id: root

  property var colors: ({})
  property var scripts: ({})
  property bool colorsLoaded: false
  property bool scriptsLoaded: false
  readonly property bool configReady: colorsLoaded && scriptsLoaded

  FileView {
    path: Quickshell.shellDir + "/colors.json"
    onLoaded: {
      try { root.colors = JSON.parse(text()); root.colorsLoaded = true; }
      catch(e) { console.log("colors.json parse error:", e); }
    }
  }

  FileView {
    path: Quickshell.shellDir + "/scripts.json"
    onLoaded: {
      try { root.scripts = JSON.parse(text()); root.scriptsLoaded = true; }
      catch(e) { console.log("scripts.json parse error:", e); }
    }
  }

  // palette
  readonly property color colBg: colors.bg || "#000000"
  readonly property color colMantle: colors.mantle || "#181825"
  readonly property color colSurface0: colors.surface0 || "#313244"
  readonly property color colSurface1: colors.surface1 || "#6c7086"
  readonly property color colSubtext0: colors.subtext0 || "#a6adc8"
  readonly property color colText: colors.text || "#cdd6f4"
  readonly property color colAccent: colors.accent || "#cba6f7"
  readonly property color colRed: colors.red || "#f38ba8"
  readonly property color colBlue: colors.blue || "#89b4fa"
  readonly property color colPeach: colors.peach || "#fab387"
  readonly property color colGreen: colors.green || "#a6e3a1"
  readonly property color colYellow: colors.yellow || "#f9e2af"

  // design tokens
  readonly property real pillRadius: 12
  readonly property real pillHeight: 32
  readonly property real iconSize: 15
  readonly property real textSize: 12.5
  readonly property string iconFont: "JetBrainsMono Nerd Font"
  readonly property string textFont: "JetBrains Mono"

  SystemClock { id: clock; precision: SystemClock.Seconds }

  // audio
  readonly property PwNode sink: Pipewire.defaultAudioSink
  readonly property PwNode source: Pipewire.defaultAudioSource
  PwObjectTracker { objects: [root.sink, root.source].filter(n => n !== null) }

  readonly property bool volMuted: !!sink?.audio?.muted
  readonly property real volValue: sink?.audio?.volume ?? 0
  readonly property int volPercent: Math.round(volValue * 100)
  readonly property bool volActive: !volMuted && volPercent > 0
  readonly property string volIcon: {
    if (volMuted) return "󰝟";
    if (volPercent >= 70) return "󰕾";
    if (volPercent >= 30) return "󰖀";
    if (volPercent > 0) return "󰕿";
    return "󰝟";
  }
  readonly property bool micMuted: !!source?.audio?.muted
  readonly property string micIcon: micMuted ? "󰍭" : "󰍬"
  readonly property real micVolValue: source?.audio?.volume ?? 0
  readonly property int micVolPercent: Math.round(micVolValue * 100)

  // battery
  readonly property bool hasBattery: UPower.displayDevice.isLaptopBattery
  readonly property int batPercent: Math.round((UPower.displayDevice.percentage ?? 1) * 100)
  readonly property bool batCharging: {
    let s = UPower.displayDevice.state;
    return s === UPowerDeviceState.Charging || s === UPowerDeviceState.FullyCharged || s === UPowerDeviceState.PendingCharge;
  }

  // bluetooth
  readonly property bool btEnabled: !!Bluetooth.defaultAdapter?.enabled
  readonly property var btConnected: Bluetooth.devices.values.filter(d => d.connected)
  readonly property bool btOn: btEnabled && btConnected.length > 0
  readonly property string btDevice: btConnected.length > 0 ? (btConnected[0].name ?? "") : ""

  // media
  readonly property var activePlayer: {
    let playing = Mpris.players.values.find(p => p.playbackState === MprisPlaybackState.Playing);
    return playing ?? Mpris.players.values[0] ?? null;
  }
  readonly property bool mediaActive: !!activePlayer && activePlayer.playbackState !== MprisPlaybackState.Stopped
  readonly property string mediaTitle: activePlayer?.trackTitle ?? ""
  readonly property string mediaArtist: activePlayer?.trackArtist ?? ""
  readonly property bool mediaPlaying: !!activePlayer && activePlayer.playbackState === MprisPlaybackState.Playing

  // wifi + power
  property string wifiIcon: ""
  property string wifiSsid: ""
  property string wifiSignal: "0"
  property string wifiIp: ""
  property bool wifiOn: false
  property string powerIcon: ""
  property string powerProfile: "balanced"

  // cpu + memory + temp
  property string cpuPercent: "0"
  property string memPercent: "0"
  property int cpuTemp: -1
  property var lastCpuStats: null

  // weather
  property string weatherIcon: ""
  property string weatherTemp: "--"
  property string weatherDesc: ""
  property string weatherFeelsLike: ""
  property string weatherHumidity: ""
  property string weatherWind: ""
  property string weatherLocation: ""
  property string weatherLastUpdated: ""
  property string weatherPubIp: ""
  property string weatherRain: ""
  property var weatherHourly: []
  property var weatherTomorrow: null
  property string weatherError: ""
  property int weatherRetries: 0
  property var weatherPopoutScreen: null
  readonly property bool weatherPopoutOpen: weatherPopoutScreen !== null

  // pomodoro
  property real pomodoroEndTime: 0
  property string pomodoroTask: ""
  property var pomodoroPopoutScreen: null
  readonly property bool pomodoroPopoutOpen: pomodoroPopoutScreen !== null
  property var pomodoroRecent: []
  readonly property bool pomodoroActive: pomodoroEndTime > 0 && clock.date.getTime() / 1000 < pomodoroEndTime
  readonly property string pomodoroText: {
    if (!pomodoroActive) return "󰔧";
    let remaining = Math.max(0, pomodoroEndTime - clock.date.getTime() / 1000);
    let min = Math.floor(remaining / 60);
    let sec = Math.floor(remaining % 60);
    return "󰔧 " + String(min).padStart(2, '0') + ":" + String(sec).padStart(2, '0');
  }

  function startPomodoro(task) {
    pomodoroTask = task;
    pomodoroEndTime = Date.now() / 1000 + 1500;
    pomodoroPopoutScreen = null;
    Quickshell.execDetached(["bash", "-c",
      "mkdir -p $HOME/.local/share && printf '%s - %s\\n' \"$(date '+%Y-%m-%d %H:%M')\" \"$1\" >> $HOME/.local/share/pomodoro.log",
      "_", task]);
  }

  function stopPomodoro() {
    if (pomodoroEndTime > 0) {
      let startTime = pomodoroEndTime - 1500;
      let elapsed = Math.floor((Date.now() / 1000 - startTime) / 60);
      let task = pomodoroTask;
      Quickshell.execDetached(["notify-send", "Pomodoro cancelled", task + " (" + elapsed + " min)"]);
      Quickshell.execDetached(["bash", "-c",
        "printf '%s - %s (cancelled after %smin)\\n' \"$(date '+%Y-%m-%d %H:%M')\" \"$1\" \"$2\" >> $HOME/.local/share/pomodoro.log",
        "_", task, String(elapsed)]);
    }
    pomodoroEndTime = 0;
    pomodoroTask = "";
  }

  Timer {
    running: root.pomodoroEndTime > 0
    interval: 1000; repeat: true
    onTriggered: {
      if (Date.now() / 1000 >= root.pomodoroEndTime) {
        let task = root.pomodoroTask;
        root.pomodoroEndTime = 0;
        root.pomodoroTask = "";
        Quickshell.execDetached(["notify-send", "-u", "critical", "Pomodoro done", task + ", take a break"]);
      }
    }
  }

  Process {
    running: true
    command: ["bash", "-c", "if [ -f $HOME/.local/share/pomodoro.log ]; then grep -v cancelled $HOME/.local/share/pomodoro.log | sed 's/^[^ ]* [^ ]* - //' | tac | awk '!seen[$0]++' | head -10; fi"]
    stdout: SplitParser {
      onRead: data => { let t = data.trim(); if (t) root.pomodoroRecent = [...root.pomodoroRecent, t]; }
    }
  }

  // caffeine
  property string caffeineIcon: "󰛚"
  property bool caffeineActive: false

  // misc
  property bool recording: false
  property bool capsLock: false
  property bool numLock: false
  property real lastBrightness: -1

  // overlay state
  property bool launcherOpen: false
  property string launcherSearch: ""
  property int launcherIndex: 0
  property bool sessionOpen: false
  property bool wallpickerOpen: false
  property bool osdVisible: false
  property string osdIcon: ""
  property real osdValue: 0
  property int unreadCount: 0
  property bool notifPanelOpen: false
  property var wallpaperList: []

  // tooltip
  property string tooltipText: ""
  property bool tooltipVisible: false
  property var tooltipScreen: null
  property real tooltipX: 0
  Timer { id: tooltipTimer; interval: 400; onTriggered: root.tooltipVisible = true }
  function showTooltip(text, screen, x) { tooltipText = text; tooltipScreen = screen; tooltipX = x || 0; tooltipVisible = false; tooltipTimer.restart(); }
  function hideTooltip() { tooltipTimer.stop(); tooltipVisible = false; tooltipText = ""; }

  ListModel { id: toastModel }
  ListModel { id: notifHistory }

  NotificationServer {
    keepOnReload: true
    bodySupported: true
    bodyMarkupSupported: true
    actionsSupported: true
    imageSupported: true

    onNotification: notification => {
      notification.tracked = true;
      root.unreadCount = root.unreadCount + 1;

      let entry = {
        summary: notification.summary || "",
        body: notification.body || "",
        appName: notification.appName || "",
        urgency: notification.urgency,
        nid: notification.id,
        ts: Qt.formatDateTime(clock.date, "hh:mm")
      };

      notifHistory.insert(0, entry);
      if (notifHistory.count > 50) notifHistory.remove(50, notifHistory.count - 50);

      toastModel.insert(0, entry);
      if (toastModel.count > 5) toastModel.remove(5, toastModel.count - 5);

      if (notification.urgency !== NotificationUrgency.Critical) {
        let nid = notification.id;
        Qt.createQmlObject(
          'import QtQuick; Timer { interval: 5000; running: true; onTriggered: { for (let i = 0; i < toastModel.count; i++) { if (toastModel.get(i).nid === ' + nid + ') { toastModel.remove(i); break; } } destroy(); } }',
          root
        );
      }
    }
  }

  // global shortcuts
  GlobalShortcut { appid: "quickshell"; name: "toggle-launcher"; onPressed: { root.launcherOpen = !root.launcherOpen; if (root.launcherOpen) { root.launcherSearch = ""; root.launcherIndex = 0; } } }
  GlobalShortcut { appid: "quickshell"; name: "toggle-session"; onPressed: root.sessionOpen = !root.sessionOpen }
  GlobalShortcut { appid: "quickshell"; name: "toggle-wallpicker"; onPressed: root.wallpickerOpen = !root.wallpickerOpen }
  GlobalShortcut { appid: "quickshell"; name: "toggle-notif-panel"; onPressed: { root.notifPanelOpen = !root.notifPanelOpen; if (root.notifPanelOpen) root.unreadCount = 0; } }
  GlobalShortcut { appid: "quickshell"; name: "dismiss-notif"; onPressed: { if (toastModel.count > 0) toastModel.remove(0); } }
  GlobalShortcut { appid: "quickshell"; name: "dismiss-all-notif"; onPressed: toastModel.clear() }

  Connections {
    target: root.sink?.audio ?? null
    function onVolumeChanged() { root.osdValue = root.volValue; root.osdIcon = root.volIcon; root.osdVisible = true; osdHideTimer.restart(); }
    function onMutedChanged() { root.osdValue = root.volMuted ? 0 : root.volValue; root.osdIcon = root.volIcon; root.osdVisible = true; osdHideTimer.restart(); }
  }
  Connections {
    target: root.source?.audio ?? null
    function onVolumeChanged() { root.osdValue = root.micVolValue; root.osdIcon = root.micIcon; root.osdVisible = true; osdHideTimer.restart(); }
    function onMutedChanged() { root.osdValue = root.micMuted ? 0 : root.micVolValue; root.osdIcon = root.micIcon; root.osdVisible = true; osdHideTimer.restart(); }
  }
  Timer { id: osdHideTimer; interval: 2000; onTriggered: root.osdVisible = false }

  // cpu + memory + temp, delta-based for accurate instantaneous readings
  Process {
    id: cpuMemProc
    command: ["bash", "-c", "head -1 /proc/stat; awk '/MemTotal/{t=$2} /MemAvailable/{a=$2} END{printf \"%.0f\\n\", (t-a)/t*100}' /proc/meminfo; t=$(cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null); echo \"T${t:--1}\""]
    stdout: SplitParser {
      onRead: data => {
        if (!data) return;
        let d = data.trim();
        if (d.startsWith("cpu ")) {
          let p = d.split(/\s+/);
          let idle = parseInt(p[4]) + parseInt(p[5]);
          let total = 0;
          for (let i = 1; i < 8; i++) total += parseInt(p[i]);
          if (root.lastCpuStats) {
            let dt = total - root.lastCpuStats.total;
            let di = idle - root.lastCpuStats.idle;
            root.cpuPercent = dt > 0 ? Math.round(100 * (1 - di / dt)).toString() : "0";
          }
          root.lastCpuStats = { total: total, idle: idle };
        } else if (d.startsWith("T")) {
          let t = parseInt(d.substring(1));
          root.cpuTemp = t > 0 ? Math.round(t / 1000) : -1;
        } else {
          root.memPercent = d;
        }
      }
    }
  }
  Timer { interval: 2000; running: true; repeat: true; triggeredOnStart: true; onTriggered: cpuMemProc.running = true }

  // wifi + power, longer interval since nmcli is slow
  Process {
    id: sysProc
    command: root.scripts.sysinfo ? [root.scripts.sysinfo] : ["true"]
    stdout: SplitParser {
      onRead: data => {
        try {
          let d = JSON.parse(data);
          root.wifiIcon = d.wifi.icon; root.wifiSsid = d.wifi.ssid;
          root.wifiSignal = d.wifi.signal; root.wifiIp = d.wifi.ip;
          root.wifiOn = d.wifi.status === "enabled";
          root.powerIcon = d.power.icon; root.powerProfile = d.power.profile;
        } catch(e) {}
      }
    }
  }
  Timer { interval: 5000; running: root.scriptsLoaded; repeat: true; triggeredOnStart: true; onTriggered: { if (!sysProc.running) sysProc.running = true } }

  // weather
  function refreshWeather() {
    if (!weatherRefreshProc.running) weatherRefreshProc.running = true;
  }
  function _parseWeather(data) {
    try {
      let w = JSON.parse(data);
      root.weatherIcon = w.icon; root.weatherTemp = w.temp;
      root.weatherDesc = w.desc || "";
      root.weatherFeelsLike = w.feelsLike || "";
      root.weatherHumidity = w.humidity || "";
      root.weatherWind = w.wind || "";
      root.weatherLocation = w.location || "";
      root.weatherHourly = w.hourly || [];
      root.weatherTomorrow = w.tomorrow || null;
      root.weatherPubIp = w.pubIp || "";
      root.weatherRain = w.rain || "";
      root.weatherError = w.error || "";
      root.weatherLastUpdated = Qt.formatDateTime(new Date(), "h:mm AP");
      if (w.error) {
        if (root.weatherRetries < 5) { root.weatherRetries++; weatherRetryTimer.restart(); }
      } else {
        root.weatherRetries = 0;
      }
    } catch(e) { console.log("weather parse error:", e); }
  }
  Process {
    id: weatherRefreshProc
    command: root.scripts.weather ? [root.scripts.weather, "--refresh"] : ["true"]
    stdout: SplitParser { onRead: data => root._parseWeather(data) }
  }
  Process {
    id: weatherProc
    command: root.scripts.weather ? [root.scripts.weather] : ["true"]
    stdout: SplitParser { onRead: data => root._parseWeather(data) }
  }
  Timer { interval: 900000; running: root.scriptsLoaded; repeat: true; triggeredOnStart: true; onTriggered: { if (!weatherProc.running) weatherProc.running = true } }
  Timer { id: weatherRetryTimer; interval: 30000; onTriggered: { if (!weatherRefreshProc.running) weatherRefreshProc.running = true } }

  // caffeine
  Process {
    id: cafProc
    command: root.scripts.caffeine ? [root.scripts.caffeine, "status"] : ["true"]
    stdout: SplitParser {
      onRead: data => { try { let cf = JSON.parse(data); root.caffeineIcon = cf.icon; root.caffeineActive = cf.active; } catch(e) {} }
    }
  }
  Timer { interval: 2000; running: root.scriptsLoaded; repeat: true; triggeredOnStart: true; onTriggered: { if (!cafProc.running) cafProc.running = true } }

  // misc
  Process {
    id: miscProc
    command: ["bash", "-c", "rec=$(pgrep -x wl-screenrec > /dev/null && echo 1 || echo 0); caps=$(cat /sys/class/leds/input*::capslock/brightness 2>/dev/null | head -1); num=$(cat /sys/class/leds/input*::numlock/brightness 2>/dev/null | head -1); echo \"$rec ${caps:-0} ${num:-0}\""]
    stdout: SplitParser {
      onRead: data => { let p = data.trim().split(" "); root.recording = p[0] === "1"; root.capsLock = p[1] === "1"; root.numLock = p[2] === "1"; }
    }
  }
  Timer { interval: 1000; running: true; repeat: true; triggeredOnStart: true; onTriggered: { if (!miscProc.running) miscProc.running = true } }

  // brightness, -m flag for machine-readable percentage output
  Process {
    id: brightProc
    command: ["bash", "-c", root.scripts.brightnessctl ? root.scripts.brightnessctl + " -m | head -1 | cut -d, -f4 | tr -d '%'" : "echo -1"]
    stdout: SplitParser {
      onRead: data => {
        let val = parseFloat(data.trim());
        if (val < 0) return;
        let norm = val / 100;
        if (root.lastBrightness >= 0 && Math.abs(norm - root.lastBrightness) > 0.005) {
          root.osdValue = norm;
          root.osdIcon = norm > 0.7 ? "󰐀" : (norm > 0.3 ? "󰏿" : "󰏾");
          root.osdVisible = true;
          osdHideTimer.restart();
        }
        root.lastBrightness = norm;
      }
    }
  }
  Timer { interval: 500; running: root.scriptsLoaded; repeat: true; triggeredOnStart: true; onTriggered: { if (!brightProc.running) brightProc.running = true } }

  // wallpaper list
  Process {
    running: true
    command: ["bash", "-c", "find $HOME/dotfiles/wallpapers -type f \\( -name '*.jpg' -o -name '*.png' -o -name '*.webp' \\) | sort"]
    stdout: SplitParser {
      onRead: data => { let p = data.trim(); if (p !== "") root.wallpaperList = [...root.wallpaperList, p]; }
    }
  }

  // per-monitor bars
  Variants {
    model: Quickshell.screens
    Bar {}
  }

  // overlays
  Osd {}
  Notifications {}
  Launcher {}
  SessionMenu {}
  WallpaperPicker {}
  // tooltip overlay, x positioned via mapToItem from bar pills
  Variants {
    model: Quickshell.screens
    PanelWindow {
      required property var modelData
      screen: modelData
      visible: root.tooltipVisible && root.tooltipScreen === modelData && root.tooltipText !== ""
      anchors { top: true; left: true; right: true }
      margins { top: 42 }
      exclusiveZone: -1
      implicitHeight: ttBox.height + 4
      color: "transparent"

      Rectangle {
        id: ttBox
        x: Math.max(8, Math.min(parent.width - width - 8, root.tooltipX - width / 2))
        y: 2
        width: ttCol.implicitWidth + 24; height: ttCol.implicitHeight + 14; radius: 8
        color: root.colMantle
        border.width: 1; border.color: Qt.rgba(root.colSurface1.r, root.colSurface1.g, root.colSurface1.b, 0.3)

        Column {
          id: ttCol; anchors.centerIn: parent; spacing: 1

          Repeater {
            model: root.tooltipText.split('\n')
            Text {
              required property var modelData
              required property int index
              text: modelData
              font.family: root.textFont
              font.pixelSize: index === 0 ? 11 : 10
              font.weight: index === 0 ? Font.Bold : Font.Normal
              color: index === 0 ? root.colText : root.colSubtext0
            }
          }
        }
      }
    }
  }
}
