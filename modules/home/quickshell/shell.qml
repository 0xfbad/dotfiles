import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
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
  readonly property real pillHeight: 28
  readonly property real iconSize: 18
  readonly property real textSize: 12.5
  readonly property string iconFont: "Material Symbols Rounded"
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
    if (volMuted) return "volume_off";
    if (volPercent >= 70) return "volume_up";
    if (volPercent >= 30) return "volume_down";
    if (volPercent > 0) return "volume_mute";
    return "volume_off";
  }
  readonly property bool micMuted: !!source?.audio?.muted
  readonly property string micIcon: micMuted ? "mic_off" : "mic"
  readonly property real micVolValue: source?.audio?.volume ?? 0
  readonly property int micVolPercent: Math.round(micVolValue * 100)

  // battery
  readonly property bool hasBattery: UPower.displayDevice.isLaptopBattery
  readonly property int batPercent: Math.round((UPower.displayDevice.percentage ?? 1) * 100)
  readonly property bool batCharging: {
    let s = UPower.displayDevice.state;
    return s === UPowerDeviceState.Charging || s === UPowerDeviceState.FullyCharged || s === UPowerDeviceState.PendingCharge;
  }
  readonly property string batIcon: {
    if (batCharging) return "battery_charging_full";
    if (batPercent >= 90) return "battery_full";
    if (batPercent >= 70) return "battery_5_bar";
    if (batPercent >= 50) return "battery_4_bar";
    if (batPercent >= 30) return "battery_3_bar";
    if (batPercent >= 10) return "battery_2_bar";
    return "battery_alert";
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
  readonly property string mediaArtUrl: activePlayer?.trackArtUrl ?? ""
  property string mediaArtLocal: ""

  // download album art to local file for ColorQuantizer (can't load URLs)
  onMediaArtUrlChanged: {
    if (mediaArtUrl === "") { mediaArtLocal = ""; return; }
    if (mediaArtUrl.startsWith("file://")) { mediaArtLocal = mediaArtUrl; return; }
    artDownloader.running = true;
  }
  Process {
    id: artDownloader
    command: ["bash", "-c", "f=/tmp/qs-album-art-$(echo \"$1\" | md5sum | cut -d' ' -f1).jpg; [ -f \"$f\" ] && echo \"$f\" || { curl -sf -o \"$f\" \"$1\" && echo \"$f\" || echo ''; }", "_", root.mediaArtUrl]
    stdout: SplitParser {
      onRead: data => { let p = data.trim(); if (p) root.mediaArtLocal = "file://" + p; }
    }
  }

  // media popout
  property var mediaPopoutScreen: null
  readonly property bool mediaPopoutOpen: mediaPopoutScreen !== null

  ColorQuantizer {
    id: artColorizer
    source: root.mediaArtLocal
    depth: 0
    rescaleSize: 64
  }
  readonly property color mediaDominant: {
    let c = artColorizer.colors?.[0];
    if (!c) return root.colAccent;
    return Qt.rgba(c.r * 0.5 + colAccent.r * 0.5, c.g * 0.5 + colAccent.g * 0.5, c.b * 0.5 + colAccent.b * 0.5, 1);
  }

  // position tracking for media popout
  Timer {
    running: root.mediaPlaying && root.mediaPopoutOpen
    interval: 1000; repeat: true
    onTriggered: { if (root.activePlayer) root.activePlayer.positionChanged(); }
  }

  function formatTime(seconds) {
    if (isNaN(seconds) || seconds < 0) return "0:00";
    let m = Math.floor(seconds / 60);
    let s = Math.floor(seconds % 60);
    return m + ":" + String(s).padStart(2, '0');
  }

  // audio visualizer (cava)
  property var cavaBars: [0,0,0,0,0,0,0,0,0,0,0,0]
  Process {
    id: cavaProc
    command: root.scripts.cava ? [root.scripts.cava] : ["true"]
    running: root.scriptsLoaded && root.mediaActive
    stdout: SplitParser {
      onRead: data => {
        let vals = data.trim().split(";").map(v => parseInt(v) || 0);
        if (vals.length >= 12) root.cavaBars = vals;
      }
    }
  }
  // restart cava when media becomes active again
  onMediaActiveChanged: {
    if (mediaActive && scriptsLoaded && !cavaProc.running) cavaProc.running = true;
  }

  // battery details (from sysfs)
  property string batPower: ""
  property string batTimeLeft: ""
  property string batHealth: ""
  property string batCycles: ""
  property string batStatus: ""
  property var batHistory: []
  property var batPopoutScreen: null
  readonly property bool batPopoutOpen: batPopoutScreen !== null

  Process {
    id: batDetailProc
    command: ["bash", "-c", "awk -F= '{a[$1]=$2} END { v=a[\"POWER_SUPPLY_VOLTAGE_NOW\"]+0; c=a[\"POWER_SUPPLY_CURRENT_NOW\"]+0; w=v*c/1e12; s=a[\"POWER_SUPPLY_STATUS\"]; now=a[\"POWER_SUPPLY_CHARGE_NOW\"]+0; full=a[\"POWER_SUPPLY_CHARGE_FULL\"]+0; design=a[\"POWER_SUPPLY_CHARGE_FULL_DESIGN\"]+0; pw=sprintf(\"%.1fW\",w); tl=\"\"; if(c>1000 && s==\"Discharging\"){h=now/c; tl=sprintf(\"%.0fh %02.0fm\",h,h*60%60)} else if(c>1000 && s==\"Charging\"){h=(full-now)/c; tl=sprintf(\"%.0fh %02.0fm\",h,h*60%60)}; hl=(design>0)?sprintf(\"%.0f%%\",full*100/design):\"\"; printf \"%s|%s|%s|%s|%s\\n\",pw,tl,hl,a[\"POWER_SUPPLY_CYCLE_COUNT\"],s }' /sys/class/power_supply/BAT0/uevent 2>/dev/null"]
    stdout: SplitParser {
      onRead: data => {
        let p = data.trim().split("|");
        root.batPower = p[0] || "";
        root.batTimeLeft = p[1] || "";
        root.batHealth = p[2] || "";
        root.batCycles = p[3] || "";
        root.batStatus = p[4] || "";
      }
    }
  }
  Timer {
    interval: 5000; running: root.hasBattery; repeat: true; triggeredOnStart: true
    property int tick: 0
    onTriggered: {
      if (!batDetailProc.running) batDetailProc.running = true;
      tick++;
      // sample history every 30s, keep 4 hours (480 points)
      if (tick % 6 === 0) {
        let entry = { pct: root.batPercent, charging: root.batCharging, ts: Date.now() };
        root.batHistory = [...root.batHistory, entry].slice(-480);
      }
    }
  }

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

  // network
  property var netRxHistory: []
  property var netTxHistory: []
  property real netRxSpeed: 0
  property real netTxSpeed: 0
  property real netRxSession: 0
  property real netTxSession: 0
  property var lastNetBytes: null
  property var sysPopoutScreen: null
  readonly property bool sysPopoutOpen: sysPopoutScreen !== null

  function formatBytes(b) {
    if (b >= 1073741824) return (b / 1073741824).toFixed(1) + " GB";
    if (b >= 1048576) return (b / 1048576).toFixed(1) + " MB";
    if (b >= 1024) return (b / 1024).toFixed(0) + " KB";
    return Math.round(b) + " B";
  }
  function formatSpeed(bps) { return formatBytes(bps) + "/s"; }

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

  // pomodoro + todo
  property real pomodoroEndTime: 0
  property string pomodoroTask: ""
  property var pomodoroPopoutScreen: null
  readonly property bool pomodoroPopoutOpen: pomodoroPopoutScreen !== null
  property var pomodoroRecent: []
  property int pomodoroTab: 0
  property var todoItems: []
  readonly property int todoIncomplete: todoItems.filter(t => !t.done).length

  function saveTodos() {
    let json = JSON.stringify(root.todoItems);
    Quickshell.execDetached(["bash", "-c",
      "printf '%s' \"$1\" > $HOME/.local/share/quickshell-todos.json.tmp && mv $HOME/.local/share/quickshell-todos.json.tmp $HOME/.local/share/quickshell-todos.json",
      "_", json]);
  }
  function addTodo(text) {
    root.todoItems = [...root.todoItems, {id: Date.now().toString(), text: text, done: false}];
    saveTodos();
  }
  function toggleTodo(id) {
    root.todoItems = root.todoItems.map(t => t.id === id ? Object.assign({}, t, {done: !t.done}) : t);
    saveTodos();
  }
  function removeTodo(id) {
    root.todoItems = root.todoItems.filter(t => t.id !== id);
    saveTodos();
  }
  readonly property bool pomodoroActive: pomodoroEndTime > 0 && clock.date.getTime() / 1000 < pomodoroEndTime
  readonly property string pomodoroText: {
    if (!pomodoroActive) return "";
    let remaining = Math.max(0, pomodoroEndTime - clock.date.getTime() / 1000);
    let min = Math.floor(remaining / 60);
    let sec = Math.floor(remaining % 60);
    return String(min).padStart(2, '0') + ":" + String(sec).padStart(2, '0');
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
      Quickshell.execDetached(["notify-send", "-a", "pomodoro", "cancelled", task + " (" + elapsed + " min)"]);
      Quickshell.execDetached(["bash", "-c",
        "printf '%s - %s (cancelled after %smin)\\n' \"$(date '+%Y-%m-%d %H:%M')\" \"$1\" \"$2\" >> $HOME/.local/share/pomodoro.log",
        "_", task, String(elapsed)]);
    }
    pomodoroEndTime = 0;
    pomodoroTask = "";
  }

  function removeRecentPomodoro(task) {
    root.pomodoroRecent = root.pomodoroRecent.filter(t => t !== task);
    // remove matching lines from log so they don't reappear on reload
    Quickshell.execDetached(["bash", "-c",
      "f=$HOME/.local/share/pomodoro.log; [ -f \"$f\" ] && { while IFS= read -r line; do t=\"${line#* - }\"; case \"$t\" in \"$1\"|\"$1 (cancelled\"*) ;; *) printf '%s\\n' \"$line\" ;; esac; done < \"$f\" > \"$f.tmp\" && mv \"$f.tmp\" \"$f\"; }",
      "_", task]);
  }

  Timer {
    running: root.pomodoroEndTime > 0
    interval: 1000; repeat: true
    onTriggered: {
      if (Date.now() / 1000 >= root.pomodoroEndTime) {
        let task = root.pomodoroTask;
        root.pomodoroEndTime = 0;
        root.pomodoroTask = "";
        Quickshell.execDetached(["notify-send", "-a", "pomodoro", "-u", "critical", "done", task + ", take a break"]);
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

  // load todos on startup
  Process {
    running: true
    command: ["bash", "-c", "cat $HOME/.local/share/quickshell-todos.json 2>/dev/null || echo '[]'"]
    stdout: SplitParser {
      onRead: data => { try { root.todoItems = JSON.parse(data.trim()); } catch(e) {} }
    }
  }

  // caffeine
  property string caffeineIcon: "local_cafe"
  property bool caffeineActive: false

  // misc
  property bool recording: false
  property int recX: 0
  property int recY: 0
  property int recW: 0
  property int recH: 0
  property bool capsLock: false
  property bool numLock: false
  property real lastBrightness: -1

  // overlay state
  property bool cheatsheetOpen: false
  property bool launcherOpen: false
  property string launcherSearch: ""
  property int launcherIndex: 0
  property bool sessionOpen: false
  property bool clipboardOpen: false
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
  GlobalShortcut { appid: "quickshell"; name: "toggle-cheatsheet"; onPressed: root.cheatsheetOpen = !root.cheatsheetOpen }
  GlobalShortcut { appid: "quickshell"; name: "toggle-launcher"; onPressed: { root.launcherOpen = !root.launcherOpen; if (root.launcherOpen) { root.launcherSearch = ""; root.launcherIndex = 0; } } }
  GlobalShortcut { appid: "quickshell"; name: "toggle-session"; onPressed: root.sessionOpen = !root.sessionOpen }
  GlobalShortcut { appid: "quickshell"; name: "toggle-clipboard"; onPressed: root.clipboardOpen = !root.clipboardOpen }
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

  // network throughput from /proc/net/dev
  Process {
    id: netProc
    command: ["bash", "-c", "awk 'NR>2 && !/lo:/{rx+=$2; tx+=$10} END{print rx, tx}' /proc/net/dev"]
    stdout: SplitParser {
      onRead: data => {
        let parts = data.trim().split(" ");
        let rx = parseInt(parts[0]) || 0;
        let tx = parseInt(parts[1]) || 0;
        let now = Date.now() / 1000;
        if (root.lastNetBytes) {
          let dt = now - root.lastNetBytes.time;
          if (dt > 0) {
            root.netRxSpeed = Math.max(0, (rx - root.lastNetBytes.rx) / dt);
            root.netTxSpeed = Math.max(0, (tx - root.lastNetBytes.tx) / dt);
            root.netRxSession += Math.max(0, rx - root.lastNetBytes.rx);
            root.netTxSession += Math.max(0, tx - root.lastNetBytes.tx);
            root.netRxHistory = [...root.netRxHistory, root.netRxSpeed].slice(-60);
            root.netTxHistory = [...root.netTxHistory, root.netTxSpeed].slice(-60);
          }
        }
        root.lastNetBytes = { rx: rx, tx: tx, time: now };
      }
    }
  }
  Timer { interval: 2000; running: true; repeat: true; triggeredOnStart: true; onTriggered: { if (!netProc.running) netProc.running = true } }

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
    command: ["bash", "-c", "rec=$(pgrep -x wf-recorder > /dev/null && echo 1 || echo 0); caps=$(cat /sys/class/leds/input*::capslock/brightness 2>/dev/null | head -1); num=$(cat /sys/class/leds/input*::numlock/brightness 2>/dev/null | head -1); geom=$(cat /tmp/qs-rec-geom 2>/dev/null); echo \"$rec ${caps:-0} ${num:-0} ${geom:--}\""]
    stdout: SplitParser {
      onRead: data => {
        let p = data.trim().split(" ");
        root.recording = p[0] === "1";
        root.capsLock = p[1] === "1";
        root.numLock = p[2] === "1";
        // parse slurp geometry "X,Y WxH"
        if (p[0] === "1" && p.length >= 5 && p[3] !== "-") {
          let xy = p[3].split(",");
          let wh = p[4].split("x");
          root.recX = parseInt(xy[0]) || 0;
          root.recY = parseInt(xy[1]) || 0;
          root.recW = parseInt(wh[0]) || 0;
          root.recH = parseInt(wh[1]) || 0;
        } else {
          root.recX = 0; root.recY = 0; root.recW = 0; root.recH = 0;
        }
      }
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
          root.osdIcon = norm > 0.7 ? "brightness_high" : (norm > 0.3 ? "brightness_medium" : "brightness_low");
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

  // recording overlay (click-through)
  Variants {
    model: Quickshell.screens
    PanelWindow {
      id: recOverlay
      required property var modelData
      screen: modelData
      visible: root.recording && root.recW > 0
      anchors { top: true; left: true; right: true; bottom: true }
      exclusiveZone: -1
      color: "transparent"
      mask: Region {}
      WlrLayershell.layer: WlrLayer.Overlay
      WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

      Canvas {
        id: recCanvas
        anchors.fill: parent
        onPaint: {
          let ctx = getContext("2d");
          ctx.clearRect(0, 0, width, height);
          let x = root.recX, y = root.recY, w = root.recW, h = root.recH;
          if (w <= 0 || h <= 0) return;

          // dim everything outside the region
          ctx.fillStyle = "rgba(0, 0, 0, 0.3)";
          ctx.fillRect(0, 0, width, y);
          ctx.fillRect(0, y + h, width, height - y - h);
          ctx.fillRect(0, y, x, h);
          ctx.fillRect(x + w, y, width - x - w, h);

          // dashed border outside the capture region so it doesn't appear in the recording
          ctx.setLineDash([6, 4]);
          ctx.strokeStyle = root.colRed.toString();
          ctx.lineWidth = 2;
          ctx.strokeRect(x - 3, y - 3, w + 6, h + 6);
        }
      }

      Connections {
        target: root
        function onRecordingChanged() { recCanvas.requestPaint(); }
        function onRecWChanged() { recCanvas.requestPaint(); }
      }
    }
  }

  // overlays
  Osd {}
  Notifications {}
  Launcher {}
  ClipboardHistory {}
  SessionMenu {}
  WallpaperPicker {}
  Cheatsheet {}
  // tooltip overlay, x positioned via mapToItem from bar pills
  Variants {
    model: Quickshell.screens
    PanelWindow {
      required property var modelData
      screen: modelData
      visible: root.tooltipVisible && root.tooltipScreen === modelData && root.tooltipText !== ""
      anchors { top: true; left: true; right: true }
      margins { top: 38 }
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
