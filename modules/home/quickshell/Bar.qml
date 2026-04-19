import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.Pipewire

PanelWindow {
  id: bar

  required property var modelData
  screen: modelData

  anchors { top: true; left: true; right: true }
  implicitHeight: 36
  margins { top: 1; bottom: 0; left: 1; right: 1 }
  exclusiveZone: 35
  color: "transparent"

    readonly property var monitor: Hyprland.monitorFor(bar.screen)
  readonly property var activeWs: monitor?.activeWorkspace ?? null
  readonly property var wsModel: {
    let mon = bar.monitor;
    if (!mon) return [];
    return Hyprland.workspaces.values
      .filter(w => w.id > 0 && w.lastIpcObject?.monitorID === mon.id)
      .sort((a, b) => a.id - b.id);
  }

  // settings popup state (mic, bt, wifi, vol revealed on hover)
  property bool settingsOpen: false
  property bool _popupHovered: false
  Timer { id: expandTimer; interval: 250; onTriggered: bar.settingsOpen = true }
  Timer { id: collapseTimer; interval: 400; onTriggered: { if (!arrowHover.hovered && !bar._popupHovered) bar.settingsOpen = false; } }

  // clock
  Rectangle {
    id: clockBox
    anchors.centerIn: parent; z: 1
    color: Qt.rgba(root.colBg.r, root.colBg.g, root.colBg.b, 0.75)
    radius: root.pillRadius
    border.width: 1; border.color: Qt.rgba(root.colText.r, root.colText.g, root.colText.b, 0.05)
    height: 36; width: clockLayout.implicitWidth + 24

    RowLayout {
      id: clockLayout; anchors.centerIn: parent; spacing: 8
      Text { text: Qt.formatDateTime(clock.date, "ddd MMM dd"); font.family: root.textFont; font.pixelSize: root.textSize; color: root.colSubtext0 }
      Text { text: Qt.formatDateTime(clock.date, "HH:mm:ss"); font.family: root.textFont; font.pixelSize: root.textSize; font.weight: Font.Bold; color: root.colText }
    }

  }

  RowLayout {
    anchors.fill: parent; anchors.leftMargin: 4; anchors.rightMargin: 4; spacing: 6

    // left island
    Rectangle {
      color: Qt.rgba(root.colBg.r, root.colBg.g, root.colBg.b, 0.75)
      radius: root.pillRadius
      border.width: 1; border.color: Qt.rgba(root.colText.r, root.colText.g, root.colText.b, 0.05)
      Layout.preferredHeight: 36; Layout.preferredWidth: leftLayout.implicitWidth + 14
      Layout.maximumWidth: bar.width / 2 - clockBox.width / 2 - 16
      clip: true

      RowLayout {
        id: leftLayout; anchors.verticalCenter: parent.verticalCenter; anchors.left: parent.left; anchors.leftMargin: 8; spacing: 6

        // workspaces
        Item {
          id: wsContainer
          Layout.preferredWidth: wsRow.implicitWidth; Layout.preferredHeight: 28

          Rectangle {
            id: wsIndicator; width: 28; height: 28; radius: root.pillRadius; color: root.colAccent; z: 0; y: 0
            visible: bar.activeWs !== null && bar.wsModel.length > 0
            x: {
              let idx = -1;
              for (let i = 0; i < bar.wsModel.length; i++) {
                if (bar.wsModel[i].id === (bar.activeWs?.id ?? -1)) { idx = i; break; }
              }
              return idx < 0 ? 0 : idx * 32;
            }
            Behavior on x { NumberAnimation { duration: 500; easing.type: Easing.BezierSpline; easing.bezierCurve: [0.2, 0, 0, 1, 1, 1] } }
          }

          Row {
            id: wsRow; spacing: 4
            Repeater {
              model: bar.wsModel
              delegate: Rectangle {
                id: wsPill
                required property var modelData
                required property int index

                property bool isActive: modelData.id === (bar.activeWs?.id ?? -1)
                property bool isHovered: wsMouse.containsMouse
                property bool isOccupied: (modelData.lastIpcObject?.windows ?? 0) > 0

                width: 28; height: 28; radius: root.pillRadius; z: 1
                color: isActive ? "transparent"
                  : (isHovered ? Qt.rgba(root.colSurface1.r, root.colSurface1.g, root.colSurface1.b, 0.9)
                  : (isOccupied ? Qt.rgba(root.colSurface0.r, root.colSurface0.g, root.colSurface0.b, 0.7)
                  : "transparent"))
                scale: isHovered && !isActive ? 1.08 : 1.0
                Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
                Behavior on color { ColorAnimation { duration: 200 } }

                Text {
                  anchors.centerIn: parent
                  text: wsPill.modelData.id.toString()
                  font.family: root.textFont; font.pixelSize: 13
                  font.weight: wsPill.isActive ? Font.Black : (wsPill.isOccupied ? Font.Bold : Font.Medium)
                  color: wsPill.isActive ? root.colBg : (wsPill.isHovered ? root.colText : (wsPill.isOccupied ? root.colText : root.colSurface1))
                  Behavior on color { ColorAnimation { duration: 200 } }
                }

                Rectangle {
                  anchors.horizontalCenter: parent.horizontalCenter
                  anchors.bottom: parent.bottom; anchors.bottomMargin: 2
                  width: 4; height: 4; radius: 2; color: root.colSubtext0
                  visible: wsPill.isOccupied && !wsPill.isActive
                }

                MouseArea {
                  id: wsMouse; hoverEnabled: true; anchors.fill: parent
                  onClicked: Hyprland.dispatch("workspace " + wsPill.modelData.id)
                  onEntered: root.showTooltip("workspace " + wsPill.modelData.id + "\nclick to focus", bar.screen, parent.mapToItem(null, parent.width/2, 0).x + 6)
                  onExited: root.hideTooltip()
                }
              }
            }
          }
        }

        // weather
        Rectangle {
          id: weatherPill
          Layout.preferredWidth: weatherRow.implicitWidth + 20; Layout.preferredHeight: 28; radius: root.pillRadius
          color: weatherMouse.containsMouse ? Qt.rgba(root.colSurface0.r, root.colSurface0.g, root.colSurface0.b, 0.6) : Qt.rgba(root.colSurface0.r, root.colSurface0.g, root.colSurface0.b, 0.4)
          scale: weatherMouse.containsMouse ? 1.02 : 1.0
          Behavior on scale { NumberAnimation { duration: 150 } }
          Behavior on color { ColorAnimation { duration: 200 } }
          RowLayout { id: weatherRow; anchors.centerIn: parent; spacing: 6
            Text { text: root.weatherIcon; font.family: root.iconFont; font.pixelSize: root.iconSize; color: root.weatherError !== "" ? root.colRed : root.colYellow; Behavior on color { ColorAnimation { duration: 200 } } }
            Text { text: root.weatherTemp; font.family: root.textFont; font.pixelSize: root.textSize; font.weight: Font.Medium; color: root.colText }
          }
          MouseArea {
            id: weatherMouse; hoverEnabled: true; anchors.fill: parent
            onClicked: {
              if (root.weatherError !== "") { root.weatherRetries = 0; root.refreshWeather(); }
              else { root.weatherPopoutScreen = root.weatherPopoutScreen === bar.screen ? null : bar.screen; }
            }
            onEntered: root.showTooltip(root.weatherError !== "" ? "weather\nclick to retry" : "weather\nclick for details", bar.screen, parent.mapToItem(null, parent.width/2, 0).x + 6)
            onExited: root.hideTooltip()
          }
        }

        // media visualizer, stays visible for 30s after playback stops
        Timer { id: mediaHideTimer; interval: 30000; onTriggered: mediaPill.showMedia = false }
        Rectangle {
          id: mediaPill
          property bool showMedia: root.mediaActive
          onShowMediaChanged: { if (!showMedia) mediaHideTimer.stop(); }
          Component.onCompleted: { if (root.mediaActive) showMedia = true; }
          Connections {
            target: root
            function onMediaActiveChanged() {
              if (root.mediaActive) { mediaHideTimer.stop(); mediaPill.showMedia = true; }
              else { mediaHideTimer.restart(); }
            }
          }
          visible: showMedia
          Layout.preferredWidth: showMedia ? cavaViz.width + 16 : 0
          Layout.preferredHeight: 28; radius: root.pillRadius
          color: mediaMouse.containsMouse ? Qt.rgba(root.colSurface0.r, root.colSurface0.g, root.colSurface0.b, 0.4) : "transparent"
          clip: true
          Behavior on Layout.preferredWidth { NumberAnimation { duration: 400; easing.type: Easing.BezierSpline; easing.bezierCurve: [0.35, 0, 0, 1, 1, 1] } }
          Behavior on color { ColorAnimation { duration: 150 } }

          Item {
            id: cavaViz
            anchors.centerIn: parent
            width: 12 * 2 + 11 * 1.5; height: 18

            Repeater {
              model: root.cavaBars
              Rectangle {
                required property int index
                required property var modelData
                x: index * 3.5
                y: parent.height - height
                width: 2; radius: 1
                height: Math.max(3, modelData / 100 * parent.height)
                color: root.mediaPlaying ? root.colAccent : root.colSurface1
                Behavior on height { NumberAnimation { duration: 80 } }
                Behavior on color { ColorAnimation { duration: 200 } }
              }
            }
          }

          MouseArea {
            id: mediaMouse; anchors.fill: parent; hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked: mouse => {
              if (mouse.button === Qt.RightButton) Quickshell.execDetached([root.scripts.pavucontrol]);
              else { root.mediaPopoutScreen = root.mediaPopoutScreen === bar.screen ? null : bar.screen; }
            }
            onEntered: {
              let title = root.mediaArtist ? root.mediaArtist + " - " + root.mediaTitle : (root.mediaTitle || "media");
              root.showTooltip(title + "\n" + (root.mediaPlaying ? "playing" : "paused") + "\nclick for player, right-click for mixer", bar.screen, parent.mapToItem(null, parent.width/2, 0).x + 6);
            }
            onExited: root.hideTooltip()
          }
        }

        Item { visible: mediaPill.showMedia; Layout.preferredWidth: 4 }
      }
    }

    Item { Layout.fillWidth: true }

    // right island
    Rectangle {
      id: rightIsland
      color: Qt.rgba(root.colBg.r, root.colBg.g, root.colBg.b, 0.75)
      radius: root.pillRadius
      border.width: 1; border.color: Qt.rgba(root.colText.r, root.colText.g, root.colText.b, 0.05)
      Layout.preferredHeight: 36; Layout.preferredWidth: rightLayout.implicitWidth + 14
      Layout.maximumWidth: bar.width / 2 - clockBox.width / 2 - 16
      clip: true

      // scroll on right island adjusts volume
      MouseArea {
        anchors.fill: parent; acceptedButtons: Qt.NoButton; z: -1
        onWheel: wheel => {
          let audio = root.sink?.audio;
          if (!audio) return;
          audio.volume = Math.max(0, Math.min(1, audio.volume + (wheel.angleDelta.y > 0 ? 0.05 : -0.05)));
          if (audio.muted) audio.muted = false;
        }
      }

      RowLayout {
        id: rightLayout; anchors.verticalCenter: parent.verticalCenter; anchors.right: parent.right; anchors.rightMargin: 8; spacing: 6

        // settings arrow, hover or click to reveal settings panel
        Rectangle {
          Layout.preferredWidth: 20; Layout.preferredHeight: 28; radius: root.pillRadius
          color: "transparent"
          Behavior on color { ColorAnimation { duration: 150 } }
          HoverHandler { id: arrowHover }
          Connections {
            target: arrowHover
            function onHoveredChanged() {
              if (arrowHover.hovered) { collapseTimer.stop(); if (!bar.settingsOpen) expandTimer.restart(); }
              else if (!bar._popupHovered) { expandTimer.stop(); collapseTimer.restart(); }
            }
          }
          Text {
            anchors.centerIn: parent
            text: bar.settingsOpen ? "chevron_right" : "chevron_left"
            font.family: root.iconFont; font.pixelSize: 16
            color: arrowHover.hovered || bar.settingsOpen ? root.colSubtext0 : root.colSurface1
            Behavior on color { ColorAnimation { duration: 150 } }
          }
        }

        // hidden settings (icon-only, revealed by arrow)
        Item {
          id: hiddenGroup; clip: true
          Layout.preferredWidth: bar.settingsOpen ? hiddenRow.implicitWidth : 0
          Layout.preferredHeight: 28
          opacity: bar.settingsOpen ? 1 : 0
          Behavior on Layout.preferredWidth { NumberAnimation { duration: 300; easing.type: Easing.BezierSpline; easing.bezierCurve: [0.3, 0, 0, 1, 1, 1] } }
          Behavior on opacity { NumberAnimation { duration: 200 } }

          HoverHandler { id: hiddenHover }
          Connections {
            target: hiddenHover
            function onHoveredChanged() {
              bar._popupHovered = hiddenHover.hovered;
              if (hiddenHover.hovered) collapseTimer.stop();
              else if (!arrowHover.hovered) collapseTimer.restart();
            }
          }

          Row {
            id: hiddenRow; anchors.verticalCenter: parent.verticalCenter; spacing: 6

            // mic
            Rectangle {
              property bool hovered: micMouse.containsMouse
              width: micRow.implicitWidth + 20; height: root.pillHeight; radius: root.pillRadius
              color: root.micMuted ? Qt.rgba(root.colRed.r, root.colRed.g, root.colRed.b, hovered ? 0.25 : 0.15) : (hovered ? Qt.rgba(root.colSurface1.r, root.colSurface1.g, root.colSurface1.b, 0.6) : Qt.rgba(root.colSurface0.r, root.colSurface0.g, root.colSurface0.b, 0.55))
              scale: hovered ? 1.02 : 1.0
              Behavior on scale { NumberAnimation { duration: 150 } }
              Behavior on color { ColorAnimation { duration: 150 } }
              RowLayout { id: micRow; anchors.centerIn: parent; spacing: 6
                Text { text: root.micIcon; font.family: root.iconFont; font.pixelSize: root.iconSize; color: root.micMuted ? root.colRed : root.colText }
                Text { visible: !root.micMuted; text: root.micVolPercent + "%"; font.family: root.textFont; font.pixelSize: root.textSize; color: root.colText }
              }
              MouseArea {
                id: micMouse; hoverEnabled: true; anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onClicked: mouse => {
                  if (mouse.button === Qt.RightButton) Quickshell.execDetached([root.scripts.pavucontrol, "-t", "4"]);
                  else if (root.source?.audio) root.source.audio.muted = !root.source.audio.muted;
                }
                onWheel: wheel => { let a = root.source?.audio; if (!a) return; a.volume = Math.max(0, Math.min(1, a.volume + (wheel.angleDelta.y > 0 ? 0.05 : -0.05))); if (a.muted) a.muted = false; }
                onEntered: root.showTooltip("microphone - input audio\nclick to mute\nscroll to adjust\nright-click to open pavucontrol", bar.screen, parent.mapToItem(null, parent.width/2, 0).x + 6)
                onExited: root.hideTooltip()
              }
            }

            // bluetooth
            Rectangle {
              property bool hovered: btMouse.containsMouse
              width: 28; height: 28; radius: root.pillRadius
              color: hovered ? Qt.rgba(root.colSurface0.r, root.colSurface0.g, root.colSurface0.b, 0.5) : "transparent"
              scale: hovered ? 1.02 : 1.0
              Behavior on scale { NumberAnimation { duration: 150 } }
              Behavior on color { ColorAnimation { duration: 200 } }
              Text { anchors.centerIn: parent; text: root.btEnabled ? (root.btOn ? "bluetooth_connected" : "bluetooth") : "bluetooth_disabled"; font.family: root.iconFont; font.pixelSize: root.iconSize; color: root.colSubtext0 }
              MouseArea {
                id: btMouse; hoverEnabled: true; anchors.fill: parent
                onClicked: Quickshell.execDetached([root.scripts.wezterm, "start", "--class", "bluetui", "--", "bluetui"])
                onEntered: root.showTooltip("bluetooth - wireless devices\nclick to open bluetui", bar.screen, parent.mapToItem(null, parent.width/2, 0).x + 6)
                onExited: root.hideTooltip()
              }
            }

            // wifi
            Rectangle {
              property bool hovered: wifiMouse.containsMouse
              width: wifiRow.implicitWidth + 20; height: root.pillHeight; radius: root.pillRadius
              color: root.wifiOn ? Qt.rgba(root.colAccent.r, root.colAccent.g, root.colAccent.b, hovered ? 0.3 : 0.2) : (hovered ? Qt.rgba(root.colSurface1.r, root.colSurface1.g, root.colSurface1.b, 0.6) : Qt.rgba(root.colSurface0.r, root.colSurface0.g, root.colSurface0.b, 0.55))
              scale: hovered ? 1.02 : 1.0
              Behavior on scale { NumberAnimation { duration: 150 } }
              Behavior on color { ColorAnimation { duration: 200 } }
              RowLayout { id: wifiRow; anchors.centerIn: parent; spacing: 6
                Text { text: root.wifiIcon; font.family: root.iconFont; font.pixelSize: root.iconSize; color: root.wifiOn ? root.colAccent : root.colSubtext0 }
                Text { visible: root.wifiOn && root.wifiSsid !== ""; text: root.wifiSsid; font.family: root.textFont; font.pixelSize: root.textSize; color: root.colText; Layout.maximumWidth: 100; elide: Text.ElideRight }
                Text { visible: root.wifiOn && root.wifiSignal !== "0"; text: root.wifiSignal + "%"; font.family: root.textFont; font.pixelSize: 10; color: root.colSubtext0 }
                Text { visible: root.wifiOn && root.wifiIp !== ""; text: root.wifiIp; font.family: root.textFont; font.pixelSize: 10; color: root.colSubtext0 }
              }
              MouseArea {
                id: wifiMouse; hoverEnabled: true; anchors.fill: parent
                onClicked: Quickshell.execDetached([root.scripts.wezterm, "start", "--class", "wifi-tui", "--", root.scripts.wifiTui])
                onEntered: root.showTooltip("network - wifi and connectivity\nclick to open wlctl", bar.screen, parent.mapToItem(null, parent.width/2, 0).x + 6)
                onExited: root.hideTooltip()
              }
            }

            // volume
            Rectangle {
              property bool hovered: volMouse.containsMouse
              width: volRow.implicitWidth + 20; height: root.pillHeight; radius: root.pillRadius
              color: root.volMuted ? Qt.rgba(root.colRed.r, root.colRed.g, root.colRed.b, hovered ? 0.25 : 0.15) : (hovered ? Qt.rgba(root.colSurface1.r, root.colSurface1.g, root.colSurface1.b, 0.6) : Qt.rgba(root.colSurface0.r, root.colSurface0.g, root.colSurface0.b, 0.55))
              scale: hovered ? 1.02 : 1.0
              Behavior on scale { NumberAnimation { duration: 150 } }
              Behavior on color { ColorAnimation { duration: 200 } }
              RowLayout { id: volRow; anchors.centerIn: parent; spacing: 6
                Text { text: root.volIcon; font.family: root.iconFont; font.pixelSize: root.iconSize; color: root.volMuted ? root.colRed : root.colText }
                Text { visible: !root.volMuted; text: root.volPercent + "%"; font.family: root.textFont; font.pixelSize: root.textSize; color: root.colText }
              }
              MouseArea {
                id: volMouse; hoverEnabled: true; anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onClicked: mouse => {
                  if (mouse.button === Qt.RightButton) Quickshell.execDetached([root.scripts.pavucontrol, "-t", "3"]);
                  else if (root.sink?.audio) root.sink.audio.muted = !root.sink.audio.muted;
                }
                onWheel: wheel => { let a = root.sink?.audio; if (!a) return; a.volume = Math.max(0, Math.min(1, a.volume + (wheel.angleDelta.y > 0 ? 0.05 : -0.05))); if (a.muted) a.muted = false; }
                onEntered: root.showTooltip("volume - output audio\nclick to mute\nscroll to adjust\nright-click to open pavucontrol", bar.screen, parent.mapToItem(null, parent.width/2, 0).x + 6)
                onExited: root.hideTooltip()
              }
            }
          }
        }

        // caffeine
        Rectangle {
          Layout.preferredWidth: 28; Layout.preferredHeight: 28; radius: root.pillRadius
          color: root.caffeineActive ? Qt.rgba(root.colRed.r, root.colRed.g, root.colRed.b, cafMouse.containsMouse ? 0.25 : 0.15) : (cafMouse.containsMouse ? Qt.rgba(root.colSurface0.r, root.colSurface0.g, root.colSurface0.b, 0.5) : "transparent")
          scale: cafMouse.containsMouse ? 1.02 : 1.0
          Behavior on scale { NumberAnimation { duration: 150 } }
          Behavior on color { ColorAnimation { duration: 150 } }
          Text { anchors.centerIn: parent; text: root.caffeineIcon; font.family: root.iconFont; font.pixelSize: root.iconSize; color: root.caffeineActive ? root.colRed : root.colSurface1; Behavior on color { ColorAnimation { duration: 200 } } }
          MouseArea {
            id: cafMouse; hoverEnabled: true; anchors.fill: parent
            onClicked: { root.caffeineActive = !root.caffeineActive; Quickshell.execDetached(["bash", "-c", root.scripts.caffeine + " toggle"]); }
            onEntered: root.showTooltip("caffeine - prevents screen locking\nclick to toggle", bar.screen, parent.mapToItem(null, parent.width/2, 0).x + 6)
            onExited: root.hideTooltip()
          }
        }

        // recording
        Rectangle {
          visible: root.recording
          Layout.preferredWidth: root.recording ? recRow.implicitWidth + 16 : 0; Layout.preferredHeight: 28; radius: root.pillRadius
          color: recMouse.containsMouse ? Qt.rgba(root.colRed.r, root.colRed.g, root.colRed.b, 0.25) : Qt.rgba(root.colRed.r, root.colRed.g, root.colRed.b, 0.15)
          scale: recMouse.containsMouse ? 1.02 : 1.0
          Behavior on scale { NumberAnimation { duration: 150 } }
          Behavior on color { ColorAnimation { duration: 150 } }
          RowLayout { id: recRow; anchors.centerIn: parent; spacing: 4
            Text { text: "fiber_manual_record"; font.family: root.iconFont; font.pixelSize: root.iconSize; color: root.colRed }
            Text { text: "REC"; font.family: root.textFont; font.pixelSize: 11; font.weight: Font.Bold; color: root.colRed }
          }
          MouseArea {
            id: recMouse; hoverEnabled: true; anchors.fill: parent
            onClicked: Quickshell.execDetached(["bash", "-c", "pkill -INT -x wf-recorder; rm -f /tmp/qs-rec-geom; PID=$(cat /tmp/qs-rec-pid 2>/dev/null); [ -n \"$PID\" ] && tail --pid=$PID -f /dev/null 2>/dev/null || sleep 2; F=$(cat /tmp/qs-rec-file 2>/dev/null); rm -f /tmp/qs-rec-pid /tmp/qs-rec-file; [ -n \"$F\" ] && [ -f \"$F\" ] && notify-send -a recording -t 3000 'recording saved to ~/videos' \"$(basename \"$F\")\""])
            onEntered: root.showTooltip("recording\nclick to stop", bar.screen, parent.mapToItem(null, parent.width/2, 0).x + 6)
            onExited: root.hideTooltip()
          }
        }

        // cpu + memory
        Rectangle {
          id: sysPill
          property bool hovered: sysMouse.containsMouse
          Layout.preferredWidth: sysRow.implicitWidth + 20; Layout.preferredHeight: root.pillHeight; radius: root.pillRadius
          color: hovered ? Qt.rgba(root.colSurface1.r, root.colSurface1.g, root.colSurface1.b, 0.6) : Qt.rgba(root.colSurface0.r, root.colSurface0.g, root.colSurface0.b, 0.55)
          scale: hovered ? 1.02 : 1.0
          Behavior on scale { NumberAnimation { duration: 150 } }
          Behavior on color { ColorAnimation { duration: 200 } }
          RowLayout { id: sysRow; anchors.centerIn: parent; spacing: 6
            Text { text: "speed"; font.family: root.iconFont; font.pixelSize: root.iconSize; color: root.colText }
            Text { text: root.cpuPercent + "%"; Layout.preferredWidth: 26; horizontalAlignment: Text.AlignRight; font.family: root.textFont; font.pixelSize: root.textSize; font.weight: Font.Medium; color: root.colText }
            Text { visible: root.cpuTemp > 0; text: root.cpuTemp + "\u00B0"; font.family: root.textFont; font.pixelSize: 10; color: root.cpuTemp >= 80 ? root.colRed : root.colSurface1 }
            Rectangle { width: 1; height: 14; color: Qt.rgba(root.colSurface1.r, root.colSurface1.g, root.colSurface1.b, 0.5) }
            Text { text: "memory_alt"; font.family: root.iconFont; font.pixelSize: root.iconSize; color: root.colText }
            Text { text: root.memPercent + "%"; Layout.preferredWidth: 26; horizontalAlignment: Text.AlignRight; font.family: root.textFont; font.pixelSize: root.textSize; font.weight: Font.Medium; color: root.colText }
          }
          MouseArea {
            id: sysMouse; hoverEnabled: true; anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked: mouse => {
              if (mouse.button === Qt.RightButton) Quickshell.execDetached([root.scripts.wezterm, "start", "--class", "btop", "--", "btop"]);
              else { root.sysPopoutScreen = root.sysPopoutScreen === bar.screen ? null : bar.screen; }
            }
            onEntered: root.showTooltip("system - cpu, memory, network\nclick for details\nright-click to open btop", bar.screen, parent.mapToItem(null, parent.width/2, 0).x + 6)
            onExited: root.hideTooltip()
          }
        }

        // battery
        Rectangle {
          id: batPill
          visible: root.hasBattery
          property bool hovered: batMouse.containsMouse
          property bool critical: root.batPercent <= 20 && !root.batCharging
          Layout.preferredWidth: root.hasBattery ? batRow.implicitWidth + 20 : 0; Layout.preferredHeight: root.pillHeight; radius: root.pillRadius
          color: critical
            ? Qt.rgba(root.colRed.r, root.colRed.g, root.colRed.b, 0.2)
            : (hovered ? Qt.rgba(root.colSurface1.r, root.colSurface1.g, root.colSurface1.b, 0.6) : Qt.rgba(root.colSurface0.r, root.colSurface0.g, root.colSurface0.b, 0.55))
          scale: hovered ? 1.02 : 1.0
          Behavior on scale { NumberAnimation { duration: 150 } }
          Behavior on color { ColorAnimation { duration: 200 } }
          RowLayout { id: batRow; anchors.centerIn: parent; spacing: 6
            Text { text: root.batIcon; font.family: root.iconFont; font.pixelSize: root.iconSize; color: batPill.critical ? root.colRed : root.colText; Behavior on color { ColorAnimation { duration: 200 } } }
            Text { text: root.batPercent + "%"; font.family: root.textFont; font.pixelSize: root.textSize; font.weight: Font.Medium; color: batPill.critical ? root.colRed : root.colText; Behavior on color { ColorAnimation { duration: 200 } } }
            Rectangle { width: 1; height: 14; color: Qt.rgba(root.colSurface1.r, root.colSurface1.g, root.colSurface1.b, 0.5) }
            Text { text: root.powerIcon; font.family: root.iconFont; font.pixelSize: 14; color: root.colSubtext0 }
          }
          MouseArea {
            id: batMouse; hoverEnabled: true; anchors.fill: parent
            onClicked: { root.batPopoutScreen = root.batPopoutScreen === bar.screen ? null : bar.screen; }
            onEntered: root.showTooltip("battery\nclick for details", bar.screen, parent.mapToItem(null, parent.width/2, 0).x + 6)
            onExited: root.hideTooltip()
          }
        }

        // notifications
        Rectangle {
          Layout.preferredWidth: 28; Layout.preferredHeight: 28; radius: root.pillRadius
          color: bellMouse.containsMouse ? Qt.rgba(root.colSurface0.r, root.colSurface0.g, root.colSurface0.b, 0.4) : "transparent"
          Behavior on color { ColorAnimation { duration: 150 } }
          Text { anchors.centerIn: parent; text: root.unreadCount > 0 ? "notifications_active" : "notifications"; font.family: root.iconFont; font.pixelSize: root.iconSize; color: root.unreadCount > 0 ? root.colAccent : root.colSurface1; Behavior on color { ColorAnimation { duration: 200 } } }
          Rectangle {
            visible: root.unreadCount > 0; anchors.top: parent.top; anchors.right: parent.right; anchors.topMargin: 2; anchors.rightMargin: 2
            width: 14; height: 14; radius: 7; color: root.colRed
            Text { anchors.centerIn: parent; text: root.unreadCount > 9 ? "9+" : root.unreadCount.toString(); font.family: root.textFont; font.pixelSize: 8; font.weight: Font.Bold; color: root.colBg }
          }
          MouseArea {
            id: bellMouse; hoverEnabled: true; anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked: mouse => {
              if (mouse.button === Qt.RightButton) { toastModel.clear(); notifHistory.clear(); root.unreadCount = 0; }
              else { root.notifPanelOpen = !root.notifPanelOpen; if (root.notifPanelOpen) root.unreadCount = 0; }
            }
            onEntered: root.showTooltip("notifications - alerts and messages\nclick to open panel\nright-click to clear all", bar.screen, parent.mapToItem(null, parent.width/2, 0).x + 6)
            onExited: root.hideTooltip()
          }
        }

        // lock indicators
        Rectangle {
          visible: root.capsLock; Layout.preferredWidth: root.capsLock ? 40 : 0; Layout.preferredHeight: 28; radius: root.pillRadius
          color: Qt.rgba(root.colAccent.r, root.colAccent.g, root.colAccent.b, 0.15)
          Text { anchors.centerIn: parent; text: "CAP"; font.family: root.textFont; font.pixelSize: 10; font.weight: Font.Bold; color: root.colAccent }
        }


      }
    }
  }

  function windDir(d) {
    let m = {"N":"North","NNE":"North Northeast","NE":"Northeast","ENE":"East Northeast","E":"East","ESE":"East Southeast","SE":"Southeast","SSE":"South Southeast","S":"South","SSW":"South Southwest","SW":"Southwest","WSW":"West Southwest","W":"West","WNW":"West Northwest","NW":"Northwest","NNW":"North Northwest"};
    return m[d] || d;
  }

  // weather popout
  PopupWindow {
    id: weatherPopout
    visible: root.weatherPopoutScreen === bar.screen
    anchor.window: bar
    anchor.rect: {
      let mapped = weatherPill.mapToItem(null, 0, 0);
      return Qt.rect(mapped.x, 0, weatherPill.width, bar.implicitHeight);
    }
    anchor.edges: Edges.Bottom
    anchor.gravity: Edges.Bottom
    anchor.adjustment: PopupAdjustment.SlideX
    implicitWidth: 400
    implicitHeight: weatherCol.implicitHeight + 36
    color: "transparent"

    HyprlandFocusGrab {
      active: root.weatherPopoutScreen === bar.screen
      windows: [weatherPopout, bar]
      onCleared: root.weatherPopoutScreen = null
    }

    Rectangle {
      anchors.fill: parent; radius: 14
      color: root.colBg
      border.width: 1; border.color: Qt.rgba(root.colText.r, root.colText.g, root.colText.b, 0.08)

      Column {
        id: weatherCol
        anchors { fill: parent; margins: 16 }
        spacing: 12

        Column {
          width: parent.width; spacing: 2
          RowLayout {
            width: parent.width
            Text {
              text: (root.weatherLocation || "Weather") + (root.weatherPubIp ? " (" + root.weatherPubIp + ")" : "")
              font.family: root.textFont; font.pixelSize: 14; font.weight: Font.Bold; color: root.colText
              Layout.fillWidth: true; elide: Text.ElideRight
            }
          }
          RowLayout {
            visible: root.weatherLastUpdated !== ""
            spacing: 8
            Text {
              text: "updated " + root.weatherLastUpdated; font.family: root.textFont; font.pixelSize: 10; color: root.colSurface1
            }
            Text {
              text: "refresh"
              font.family: root.textFont; font.pixelSize: 10
              color: refreshMouse.containsMouse ? root.colText : root.colSubtext0
              Behavior on color { ColorAnimation { duration: 150 } }
              MouseArea {
                id: refreshMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                onClicked: root.refreshWeather()
              }
            }
          }
        }

        RowLayout {
          width: parent.width; spacing: 14
          Text { text: root.weatherIcon; font.family: root.iconFont; font.pixelSize: 38; color: root.colYellow }
          Column {
            spacing: 2
            Text { text: root.weatherTemp; font.family: root.textFont; font.pixelSize: 24; color: root.colText }
            Text {
              text: root.weatherDesc; font.family: root.textFont; font.pixelSize: 12
              color: root.colSubtext0; visible: root.weatherDesc !== ""
            }
          }
        }

        Rectangle { width: parent.width; height: 1; color: Qt.rgba(root.colSurface0.r, root.colSurface0.g, root.colSurface0.b, 0.5); visible: root.weatherFeelsLike !== "" }

        GridLayout {
          visible: root.weatherFeelsLike !== ""
          width: parent.width; columns: 2; rowSpacing: 8; columnSpacing: 16
          Text { text: "Feels like"; font.family: root.textFont; font.pixelSize: 13; color: root.colSubtext0 }
          Text { text: root.weatherFeelsLike; font.family: root.textFont; font.pixelSize: 13; color: root.colText }
          Text { text: "Humidity"; font.family: root.textFont; font.pixelSize: 13; color: root.colSubtext0 }
          Text { text: root.weatherHumidity; font.family: root.textFont; font.pixelSize: 13; color: root.colText }
          Text { text: "Wind"; font.family: root.textFont; font.pixelSize: 13; color: root.colSubtext0 }
          Text {
            text: {
              let parts = root.weatherWind.split(" ");
              if (parts.length >= 3) return parts[0] + " mph " + bar.windDir(parts[2]);
              return root.weatherWind;
            }
            font.family: root.textFont; font.pixelSize: 13; color: root.colText
          }
          Text { visible: root.weatherRain !== ""; text: "Rain"; font.family: root.textFont; font.pixelSize: 13; color: root.colSubtext0 }
          Text { visible: root.weatherRain !== ""; text: root.weatherRain; font.family: root.textFont; font.pixelSize: 13; color: root.colText }
        }

        Rectangle { width: parent.width; height: 1; visible: root.weatherHourly.length > 0; color: Qt.rgba(root.colSurface0.r, root.colSurface0.g, root.colSurface0.b, 0.5) }

        RowLayout {
          visible: root.weatherHourly.length > 0
          width: parent.width; spacing: 0

          Repeater {
            model: root.weatherHourly
            delegate: Column {
              required property var modelData
              Layout.fillWidth: true; spacing: 4
              Text { anchors.horizontalCenter: parent.horizontalCenter; text: modelData.time; font.family: root.textFont; font.pixelSize: 11; color: root.colSubtext0 }
              Text { anchors.horizontalCenter: parent.horizontalCenter; text: modelData.icon; font.family: root.iconFont; font.pixelSize: 22; color: root.colYellow }
              Text { anchors.horizontalCenter: parent.horizontalCenter; text: modelData.temp + "\u00B0"; font.family: root.textFont; font.pixelSize: 13; color: root.colText }
            }
          }

          Rectangle { visible: root.weatherTomorrow !== null; Layout.preferredWidth: 1; Layout.preferredHeight: 50; color: Qt.rgba(root.colSurface1.r, root.colSurface1.g, root.colSurface1.b, 0.3) }

          Column {
            visible: root.weatherTomorrow !== null
            Layout.fillWidth: true; spacing: 4
            Text { anchors.horizontalCenter: parent.horizontalCenter; text: "Tomorrow"; font.family: root.textFont; font.pixelSize: 11; color: root.colSubtext0 }
            Text { anchors.horizontalCenter: parent.horizontalCenter; text: root.weatherTomorrow?.icon ?? ""; font.family: root.iconFont; font.pixelSize: 22; color: root.colYellow }
            Text { anchors.horizontalCenter: parent.horizontalCenter; text: (root.weatherTomorrow?.high ?? "") + "\u00B0/" + (root.weatherTomorrow?.low ?? "") + "\u00B0"; font.family: root.textFont; font.pixelSize: 12; color: root.colText }
          }
        }

        Text {
          visible: root.weatherError !== ""
          width: parent.width
          text: root.weatherError
          font.family: root.textFont; font.pixelSize: 11; color: root.colRed
          horizontalAlignment: Text.AlignLeft
        }
      }
    }
  }

  // media popout
  PopupWindow {
    id: mediaPopout
    visible: root.mediaPopoutScreen === bar.screen
    anchor.window: bar
    anchor.rect: {
      let mapped = mediaPill.mapToItem(null, 0, 0);
      return Qt.rect(mapped.x, 0, mediaPill.width, bar.implicitHeight);
    }
    anchor.edges: Edges.Bottom
    anchor.gravity: Edges.Bottom
    anchor.adjustment: PopupAdjustment.SlideX
    implicitWidth: 420
    implicitHeight: 200
    color: "transparent"

    HyprlandFocusGrab {
      active: root.mediaPopoutScreen === bar.screen
      windows: [mediaPopout, bar]
      onCleared: root.mediaPopoutScreen = null
    }

    Rectangle {
      anchors.fill: parent; radius: 14
      color: root.colBg
      border.width: 1; border.color: Qt.rgba(root.colText.r, root.colText.g, root.colText.b, 0.08)
      clip: true

      // wave visualizer background
      Canvas {
        id: waveViz
        anchors.fill: parent; z: 0

        onPaint: {
          let ctx = getContext("2d");
          ctx.clearRect(0, 0, width, height);
          let bars = root.cavaBars;
          let n = bars.length;
          if (n < 2) return;

          let smoothed = [];
          for (let i = 0; i < n; i++) {
            let sum = 0, count = 0;
            for (let j = -2; j <= 2; j++) {
              let idx = Math.max(0, Math.min(n - 1, i + j));
              sum += bars[idx]; count++;
            }
            smoothed.push(root.mediaPlaying ? sum / count : 0);
          }

          ctx.beginPath();
          ctx.moveTo(0, height);
          for (let i = 0; i < n; i++) {
            let x = i * width / (n - 1);
            let y = height - (smoothed[i] / 100) * height * 0.4;
            ctx.lineTo(x, y);
          }
          ctx.lineTo(width, height);
          ctx.closePath();
          ctx.fillStyle = Qt.rgba(root.mediaDominant.r, root.mediaDominant.g, root.mediaDominant.b, 0.12);
          ctx.fill();
        }
      }
      Connections { target: root; function onCavaBarsChanged() { waveViz.requestPaint(); } }

      RowLayout {
        anchors.fill: parent; anchors.margins: 14; spacing: 14; z: 1

        // album art
        Rectangle {
          Layout.preferredWidth: 160; Layout.preferredHeight: 160; radius: 10
          color: root.colSurface0; clip: true

          Image {
            anchors.fill: parent
            source: root.mediaArtLocal || root.mediaArtUrl
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            sourceSize.width: 160; sourceSize.height: 160
          }

          Text {
            visible: (root.mediaArtLocal || root.mediaArtUrl) === ""
            anchors.centerIn: parent
            text: "music_note"; font.family: root.iconFont; font.pixelSize: 48
            color: root.colSurface1
          }
        }

        // info + controls
        ColumnLayout {
          Layout.fillWidth: true; Layout.fillHeight: true; spacing: 4

          Text {
            text: root.mediaTitle || "Untitled"
            font.family: root.textFont; font.pixelSize: 14; font.weight: Font.Bold
            color: root.colText; elide: Text.ElideRight; Layout.fillWidth: true
          }
          Text {
            visible: root.mediaArtist !== ""
            text: root.mediaArtist
            font.family: root.textFont; font.pixelSize: 12
            color: root.colSubtext0; elide: Text.ElideRight; Layout.fillWidth: true
          }

          Item { Layout.fillHeight: true }

          // progress bar
          Rectangle {
            Layout.fillWidth: true; Layout.preferredHeight: 4; radius: 2
            color: root.colSurface0

            Rectangle {
              width: root.activePlayer?.length > 0 ? parent.width * ((root.activePlayer?.position ?? 0) / root.activePlayer.length) : 0
              height: parent.height; radius: 2
              color: root.mediaDominant
              Behavior on width { NumberAnimation { duration: 500 } }
            }

            MouseArea {
              anchors.fill: parent; cursorShape: Qt.PointingHandCursor
              onClicked: mouse => {
                if (root.activePlayer?.canSeek && root.activePlayer?.length > 0)
                  root.activePlayer.position = (mouse.x / width) * root.activePlayer.length;
              }
            }
          }

          // time labels
          RowLayout {
            Layout.fillWidth: true
            Text { text: root.formatTime(root.activePlayer?.position ?? 0); font.family: root.textFont; font.pixelSize: 10; color: root.colSurface1 }
            Item { Layout.fillWidth: true }
            Text { text: root.formatTime(root.activePlayer?.length ?? 0); font.family: root.textFont; font.pixelSize: 10; color: root.colSurface1 }
          }

          // controls
          RowLayout {
            Layout.alignment: Qt.AlignHCenter; spacing: 16

            Rectangle {
              width: 32; height: 32; radius: 16; color: prevMouse.containsMouse ? Qt.rgba(root.colSurface0.r, root.colSurface0.g, root.colSurface0.b, 0.5) : "transparent"
              Behavior on color { ColorAnimation { duration: 100 } }
              Text { anchors.centerIn: parent; text: "skip_previous"; font.family: root.iconFont; font.pixelSize: 22; color: root.colText }
              MouseArea { id: prevMouse; anchors.fill: parent; hoverEnabled: true; onClicked: { if (root.activePlayer) root.activePlayer.previous(); } }
            }

            Rectangle {
              width: 40; height: 40; radius: 20
              color: Qt.rgba(root.mediaDominant.r, root.mediaDominant.g, root.mediaDominant.b, playMouse.containsMouse ? 0.35 : 0.25)
              Behavior on color { ColorAnimation { duration: 100 } }
              Text { anchors.centerIn: parent; text: root.mediaPlaying ? "pause" : "play_arrow"; font.family: root.iconFont; font.pixelSize: 26; color: root.mediaDominant }
              MouseArea { id: playMouse; anchors.fill: parent; hoverEnabled: true; onClicked: { if (root.activePlayer) root.activePlayer.togglePlaying(); } }
            }

            Rectangle {
              width: 32; height: 32; radius: 16; color: nextMouse.containsMouse ? Qt.rgba(root.colSurface0.r, root.colSurface0.g, root.colSurface0.b, 0.5) : "transparent"
              Behavior on color { ColorAnimation { duration: 100 } }
              Text { anchors.centerIn: parent; text: "skip_next"; font.family: root.iconFont; font.pixelSize: 22; color: root.colText }
              MouseArea { id: nextMouse; anchors.fill: parent; hoverEnabled: true; onClicked: { if (root.activePlayer) root.activePlayer.next(); } }
            }
          }
        }
      }
    }
  }

  // sys info popout
  PopupWindow {
    id: sysPopout
    visible: root.sysPopoutScreen === bar.screen
    anchor.window: bar
    anchor.rect: {
      let mapped = sysPill.mapToItem(null, 0, 0);
      return Qt.rect(mapped.x, 0, sysPill.width, bar.implicitHeight);
    }
    anchor.edges: Edges.Bottom
    anchor.gravity: Edges.Bottom
    anchor.adjustment: PopupAdjustment.SlideX
    implicitWidth: 360
    implicitHeight: sysPopCol.implicitHeight + 36
    color: "transparent"

    HyprlandFocusGrab {
      active: root.sysPopoutScreen === bar.screen
      windows: [sysPopout, bar]
      onCleared: root.sysPopoutScreen = null
    }

    Rectangle {
      anchors.fill: parent; radius: 14
      color: root.colBg
      border.width: 1; border.color: Qt.rgba(root.colText.r, root.colText.g, root.colText.b, 0.08)

      Column {
        id: sysPopCol
        anchors { fill: parent; margins: 16 }
        spacing: 12

        Text { text: "System Resources"; font.family: root.textFont; font.pixelSize: 14; font.weight: Font.Bold; color: root.colText }

        // cpu + mem details
        GridLayout {
          width: parent.width; columns: 2; rowSpacing: 8; columnSpacing: 12

          RowLayout { spacing: 6
            Text { text: "speed"; font.family: root.iconFont; font.pixelSize: root.iconSize; color: root.colText }
            Text { text: "CPU"; font.family: root.textFont; font.pixelSize: 13; color: root.colSubtext0 }
          }
          Text { text: root.cpuPercent + "%" + (root.cpuTemp > 0 ? "  " + root.cpuTemp + "\u00B0C" : ""); font.family: root.textFont; font.pixelSize: 13; color: root.colText; Layout.fillWidth: true; horizontalAlignment: Text.AlignRight }

          RowLayout { spacing: 6
            Text { text: "memory_alt"; font.family: root.iconFont; font.pixelSize: root.iconSize; color: root.colText }
            Text { text: "Memory"; font.family: root.textFont; font.pixelSize: 13; color: root.colSubtext0 }
          }
          Text { text: root.memPercent + "%"; font.family: root.textFont; font.pixelSize: 13; color: root.colText; Layout.fillWidth: true; horizontalAlignment: Text.AlignRight }
        }

        Rectangle { width: parent.width; height: 1; color: Qt.rgba(root.colSurface0.r, root.colSurface0.g, root.colSurface0.b, 0.5) }

        // network header
        Text { text: "Network"; font.family: root.textFont; font.pixelSize: 13; font.weight: Font.Bold; color: root.colText }

        // current speeds
        RowLayout {
          width: parent.width; spacing: 12
          RowLayout { spacing: 4; Layout.fillWidth: true
            Text { text: "arrow_downward"; font.family: root.iconFont; font.pixelSize: 14; color: root.colBlue }
            Text { text: root.formatSpeed(root.netRxSpeed); font.family: root.textFont; font.pixelSize: 12; color: root.colText }
          }
          RowLayout { spacing: 4; Layout.fillWidth: true
            Text { text: "arrow_upward"; font.family: root.iconFont; font.pixelSize: 14; color: root.colPeach }
            Text { text: root.formatSpeed(root.netTxSpeed); font.family: root.textFont; font.pixelSize: 12; color: root.colText }
          }
        }

        // sparkline
        Rectangle {
          width: parent.width; height: 70; radius: root.pillRadius
          color: Qt.rgba(root.colSurface0.r, root.colSurface0.g, root.colSurface0.b, 0.3)

          Canvas {
            id: netCanvas
            anchors.fill: parent; anchors.margins: 4

            function drawArea(ctx, values, maxVal, color, opacity) {
              if (values.length < 2) return;
              let w = width, h = height, n = values.length;
              ctx.beginPath();
              ctx.moveTo(0, h);
              for (let i = 0; i < n; i++) {
                let x = i * w / (n - 1);
                let y = h - (maxVal > 0 ? (values[i] / maxVal) * h * 0.9 : 0);
                ctx.lineTo(x, y);
              }
              ctx.lineTo(w, h);
              ctx.closePath();
              ctx.fillStyle = Qt.rgba(color.r, color.g, color.b, opacity);
              ctx.fill();
              // stroke line on top
              ctx.beginPath();
              for (let i = 0; i < n; i++) {
                let x = i * w / (n - 1);
                let y = h - (maxVal > 0 ? (values[i] / maxVal) * h * 0.9 : 0);
                if (i === 0) ctx.moveTo(x, y); else ctx.lineTo(x, y);
              }
              ctx.strokeStyle = Qt.rgba(color.r, color.g, color.b, opacity + 0.3);
              ctx.lineWidth = 1.5;
              ctx.stroke();
            }

            onPaint: {
              let ctx = getContext("2d");
              ctx.clearRect(0, 0, width, height);
              let allVals = [...root.netRxHistory, ...root.netTxHistory];
              let maxVal = allVals.length > 0 ? Math.max(...allVals, 1024) : 1024;
              drawArea(ctx, root.netRxHistory, maxVal, root.colBlue, 0.25);
              drawArea(ctx, root.netTxHistory, maxVal, root.colPeach, 0.2);
            }
          }

          Connections {
            target: root
            function onNetRxHistoryChanged() { netCanvas.requestPaint(); }
          }
        }

        // session totals
        RowLayout {
          width: parent.width; spacing: 12
          Text { text: "Session"; font.family: root.textFont; font.pixelSize: 11; color: root.colSurface1 }
          Item { Layout.fillWidth: true }
          RowLayout { spacing: 4
            Text { text: "arrow_downward"; font.family: root.iconFont; font.pixelSize: 12; color: root.colBlue }
            Text { text: root.formatBytes(root.netRxSession); font.family: root.textFont; font.pixelSize: 11; color: root.colSubtext0 }
          }
          RowLayout { spacing: 4
            Text { text: "arrow_upward"; font.family: root.iconFont; font.pixelSize: 12; color: root.colPeach }
            Text { text: root.formatBytes(root.netTxSession); font.family: root.textFont; font.pixelSize: 11; color: root.colSubtext0 }
          }
        }
      }
    }
  }

  // battery popout
  PopupWindow {
    id: batPopout
    visible: root.batPopoutOpen && root.batPopoutScreen === bar.screen
    anchor.window: bar
    anchor.rect: {
      let mapped = batPill.mapToItem(null, 0, 0);
      return Qt.rect(mapped.x, 0, batPill.width, bar.implicitHeight);
    }
    anchor.edges: Edges.Bottom
    anchor.gravity: Edges.Bottom
    anchor.adjustment: PopupAdjustment.SlideX
    implicitWidth: 360
    implicitHeight: batPopCol.implicitHeight + 36
    color: "transparent"

    HyprlandFocusGrab {
      active: root.batPopoutScreen === bar.screen
      windows: [batPopout, bar]
      onCleared: root.batPopoutScreen = null
    }

    Rectangle {
      anchors.fill: parent; radius: 14
      color: root.colBg
      border.width: 1; border.color: Qt.rgba(root.colText.r, root.colText.g, root.colText.b, 0.08)

      Column {
        id: batPopCol
        anchors { fill: parent; margins: 16 }
        spacing: 12

        // header
        RowLayout {
          width: parent.width
          Text { text: "Battery"; font.family: root.textFont; font.pixelSize: 14; font.weight: Font.Bold; color: root.colText }
          Item { Layout.fillWidth: true }
          Text {
            text: {
              let s = root.batStatus;
              if (s === "Charging") return root.batPercent + "% charging";
              if (s === "Discharging") return root.batPercent + "%";
              if (s === "Full") return "full";
              if (s === "Not charging") return root.batPercent + "% plugged in";
              return root.batPercent + "%";
            }
            font.family: root.textFont; font.pixelSize: 13; color: root.colSubtext0
          }
        }

        // stats grid
        GridLayout {
          width: parent.width; columns: 2; rowSpacing: 6; columnSpacing: 12

          Text { text: "Power"; font.family: root.textFont; font.pixelSize: 12; color: root.colSubtext0 }
          Text { text: root.batPower; font.family: root.textFont; font.pixelSize: 12; color: root.colText; Layout.fillWidth: true; horizontalAlignment: Text.AlignRight }

          Text {
            visible: root.batTimeLeft !== ""
            text: root.batCharging ? "Time to full" : "Time left"
            font.family: root.textFont; font.pixelSize: 12; color: root.colSubtext0
          }
          Text {
            visible: root.batTimeLeft !== ""
            text: root.batTimeLeft
            font.family: root.textFont; font.pixelSize: 12; color: root.colText; Layout.fillWidth: true; horizontalAlignment: Text.AlignRight
          }

          Text { text: "Health"; font.family: root.textFont; font.pixelSize: 12; color: root.colSubtext0 }
          Text { text: root.batHealth || "—"; font.family: root.textFont; font.pixelSize: 12; color: root.colText; Layout.fillWidth: true; horizontalAlignment: Text.AlignRight }

          Text { text: "Cycles"; font.family: root.textFont; font.pixelSize: 12; color: root.colSubtext0 }
          Text { text: root.batCycles || "—"; font.family: root.textFont; font.pixelSize: 12; color: root.colText; Layout.fillWidth: true; horizontalAlignment: Text.AlignRight }
        }

        Rectangle { width: parent.width; height: 1; color: Qt.rgba(root.colSurface0.r, root.colSurface0.g, root.colSurface0.b, 0.5) }

        // graph section
        Column {
          width: parent.width; spacing: 6

          // legend
          RowLayout {
            width: parent.width
            Text { text: "History"; font.family: root.textFont; font.pixelSize: 13; font.weight: Font.Bold; color: root.colText }
            Item { Layout.fillWidth: true }
            RowLayout { spacing: 8
              RowLayout { spacing: 3
                Rectangle { width: 8; height: 8; radius: 4; color: root.colAccent }
                Text { text: "on battery"; font.family: root.textFont; font.pixelSize: 10; color: root.colSubtext0 }
              }
              RowLayout { spacing: 3
                Rectangle { width: 8; height: 8; radius: 4; color: root.colPeach }
                Text { text: "charging"; font.family: root.textFont; font.pixelSize: 10; color: root.colSubtext0 }
              }
            }
          }

          // graph
          Item {
            width: parent.width; height: 120

            // empty state
            Text {
              visible: root.batHistory.length < 2
              anchors.centerIn: parent
              text: "collecting data..."
              font.family: root.textFont; font.pixelSize: 11; color: root.colSurface1
            }

            Rectangle {
              visible: root.batHistory.length >= 2
              anchors.fill: parent; radius: root.pillRadius
              color: Qt.rgba(root.colSurface0.r, root.colSurface0.g, root.colSurface0.b, 0.3)

              // danger zone (below 20%)
              Rectangle {
                anchors.bottom: parent.bottom; anchors.left: parent.left; anchors.right: parent.right
                anchors.leftMargin: 28; anchors.bottomMargin: 18
                height: (parent.height - 18) * 0.2; radius: 4
                color: Qt.rgba(root.colRed.r, root.colRed.g, root.colRed.b, 0.06)
                Rectangle { anchors.top: parent.top; width: parent.width; height: 1; color: Qt.rgba(root.colRed.r, root.colRed.g, root.colRed.b, 0.15) }
              }

              // y-axis labels
              Repeater {
                model: [100, 50, 20]
                Text {
                  required property var modelData
                  x: 2; y: (parent.height - 18) * (1 - modelData / 100) - 5
                  text: modelData; font.family: root.textFont; font.pixelSize: 8
                  color: Qt.rgba(root.colSurface1.r, root.colSurface1.g, root.colSurface1.b, 0.6)
                }
              }

              // grid lines
              Repeater {
                model: [100, 50, 20]
                Rectangle {
                  required property var modelData
                  x: 28; width: parent.width - 28; height: 1
                  y: (parent.height - 18) * (1 - modelData / 100)
                  color: Qt.rgba(root.colSurface1.r, root.colSurface1.g, root.colSurface1.b, 0.1)
                }
              }

              Canvas {
                id: batCanvas
                x: 28; y: 0; width: parent.width - 28; height: parent.height - 18

                onPaint: {
                  let ctx = getContext("2d");
                  ctx.clearRect(0, 0, width, height);
                  let hist = root.batHistory;
                  if (hist.length < 2) return;
                  let w = width, h = height, n = hist.length;

                  // filled area first (draw as one path per state segment)
                  for (let i = 1; i < n; i++) {
                    let x0 = (i - 1) * w / (n - 1);
                    let x1 = i * w / (n - 1);
                    let y0 = h - (hist[i-1].pct / 100) * h;
                    let y1 = h - (hist[i].pct / 100) * h;
                    let charging = hist[i].charging;
                    let pct = hist[i].pct;

                    let col;
                    if (pct <= 20 && !charging) col = root.colRed;
                    else if (charging) col = root.colPeach;
                    else col = root.colAccent;

                    ctx.beginPath();
                    ctx.moveTo(x0, h);
                    ctx.lineTo(x0, y0);
                    ctx.lineTo(x1, y1);
                    ctx.lineTo(x1, h);
                    ctx.closePath();
                    ctx.fillStyle = Qt.rgba(col.r, col.g, col.b, 0.12);
                    ctx.fill();

                    ctx.beginPath();
                    ctx.moveTo(x0, y0);
                    ctx.lineTo(x1, y1);
                    ctx.strokeStyle = Qt.rgba(col.r, col.g, col.b, 0.8);
                    ctx.lineWidth = 1.5;
                    ctx.stroke();
                  }

                  // current level dot
                  let lastY = h - (hist[n-1].pct / 100) * h;
                  let lastCol = hist[n-1].charging ? root.colPeach : (hist[n-1].pct <= 20 ? root.colRed : root.colAccent);
                  ctx.beginPath();
                  ctx.arc(w, lastY, 3, 0, 2 * Math.PI);
                  ctx.fillStyle = Qt.rgba(lastCol.r, lastCol.g, lastCol.b, 1);
                  ctx.fill();
                }
              }

              Connections {
                target: root
                function onBatHistoryChanged() { batCanvas.requestPaint(); }
              }

              // x-axis time labels
              Item {
                anchors.bottom: parent.bottom; anchors.left: parent.left; anchors.right: parent.right
                anchors.leftMargin: 28
                height: 16

                Repeater {
                  model: {
                    if (root.batHistory.length < 2) return [];
                    let first = root.batHistory[0].ts;
                    let last = root.batHistory[root.batHistory.length - 1].ts;
                    let span = last - first;
                    let labels = [];
                    // place ~4 evenly spaced labels
                    for (let i = 0; i <= 3; i++) {
                      let ts = first + (span * i / 3);
                      let d = new Date(ts);
                      let mins = Math.round((last - ts) / 60000);
                      let label = mins > 0 ? mins + "m ago" : "now";
                      let frac = i / 3;
                      labels.push({ label: label, frac: frac });
                    }
                    return labels;
                  }
                  Text {
                    required property var modelData
                    required property int index
                    x: {
                      let total = parent.width;
                      let pos = total * modelData.frac;
                      if (index === 0) return 0;
                      if (index === 3) return total - implicitWidth;
                      return pos - implicitWidth / 2;
                    }
                    text: modelData.label; font.family: root.textFont; font.pixelSize: 8
                    color: Qt.rgba(root.colSurface1.r, root.colSurface1.g, root.colSurface1.b, 0.6)
                  }
                }
              }
            }
          }
        }

        Rectangle { width: parent.width; height: 1; color: Qt.rgba(root.colSurface0.r, root.colSurface0.g, root.colSurface0.b, 0.5) }

        // power profile
        Column {
          width: parent.width; spacing: 8

          Text { text: "Power Profile"; font.family: root.textFont; font.pixelSize: 13; font.weight: Font.Bold; color: root.colText }

          RowLayout {
            width: parent.width; spacing: 6

            Repeater {
              model: [
                { name: "power-saver", icon: "eco", label: "Saver" },
                { name: "balanced", icon: "balance", label: "Balanced" },
                { name: "performance", icon: "flash_on", label: "Performance" }
              ]
              Rectangle {
                required property var modelData
                property bool active: root.powerProfile === modelData.name
                property bool hovered: ppBtnMouse.containsMouse
                Layout.fillWidth: true; height: 32; radius: root.pillRadius
                color: active
                  ? Qt.rgba(root.colAccent.r, root.colAccent.g, root.colAccent.b, 0.2)
                  : (hovered ? Qt.rgba(root.colSurface1.r, root.colSurface1.g, root.colSurface1.b, 0.4) : Qt.rgba(root.colSurface0.r, root.colSurface0.g, root.colSurface0.b, 0.3))
                Behavior on color { ColorAnimation { duration: 150 } }
                RowLayout { id: ppBtnRow; anchors.centerIn: parent; spacing: 4
                  Text { text: modelData.icon; font.family: root.iconFont; font.pixelSize: 15; color: active ? root.colAccent : root.colSubtext0; Behavior on color { ColorAnimation { duration: 150 } } }
                  Text { text: modelData.label; font.family: root.textFont; font.pixelSize: 11; color: active ? root.colAccent : root.colSubtext0; Behavior on color { ColorAnimation { duration: 150 } } }
                }
                MouseArea {
                  id: ppBtnMouse; anchors.fill: parent; hoverEnabled: true
                  onClicked: {
                    root.powerProfile = modelData.name;
                    root.powerIcon = modelData.icon;
                    Quickshell.execDetached([root.scripts.powerprofilesctl, "set", modelData.name]);
                  }
                }
              }
            }
          }
        }
      }
    }
  }

}
