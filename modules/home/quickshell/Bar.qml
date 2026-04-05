import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.SystemTray
import Quickshell.Services.Pipewire

PanelWindow {
  id: bar

  required property var modelData
  screen: modelData

  anchors { top: true; left: true; right: true }
  implicitHeight: 40
  margins { top: 1; bottom: 0; left: 6; right: 6 }
  exclusiveZone: 41
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
    radius: root.pillRadius + 2
    border.width: 1; border.color: Qt.rgba(root.colText.r, root.colText.g, root.colText.b, 0.05)
    height: 40; width: clockLayout.implicitWidth + 28

    RowLayout {
      id: clockLayout; anchors.centerIn: parent; spacing: 8
      Text { text: Qt.formatDateTime(clock.date, "ddd MMM dd"); font.family: root.textFont; font.pixelSize: root.textSize; color: root.colSubtext0 }
      Text { text: Qt.formatDateTime(clock.date, "HH:mm:ss"); font.family: root.textFont; font.pixelSize: root.textSize; font.weight: Font.Bold; color: root.colText }
    }

    MouseArea {
      anchors.fill: parent; hoverEnabled: true
      onEntered: root.showTooltip("clock\n" + Qt.formatDateTime(clock.date, "dddd, MMMM d yyyy"), bar.screen, parent.mapToItem(null, parent.width/2, 0).x + 6)
      onExited: root.hideTooltip()
    }
  }

  RowLayout {
    anchors.fill: parent; anchors.leftMargin: 4; anchors.rightMargin: 4; spacing: 6

    // left island
    Rectangle {
      color: Qt.rgba(root.colBg.r, root.colBg.g, root.colBg.b, 0.75)
      radius: root.pillRadius + 2
      border.width: 1; border.color: Qt.rgba(root.colText.r, root.colText.g, root.colText.b, 0.05)
      Layout.preferredHeight: 40; Layout.preferredWidth: leftLayout.implicitWidth + 16
      Layout.maximumWidth: bar.width / 2 - clockBox.width / 2 - 16
      clip: true

      MouseArea {
        anchors.fill: parent; acceptedButtons: Qt.NoButton
        onWheel: wheel => {
          if (wheel.angleDelta.y > 0) Hyprland.dispatch("workspace e-1");
          else Hyprland.dispatch("workspace e+1");
        }
      }

      RowLayout {
        id: leftLayout; anchors.verticalCenter: parent.verticalCenter; anchors.left: parent.left; anchors.leftMargin: 8; spacing: 6

        // workspaces
        Item {
          id: wsContainer
          Layout.preferredWidth: wsRow.implicitWidth; Layout.preferredHeight: 28

          Rectangle {
            id: wsIndicator; width: 28; height: 28; radius: 8; color: root.colAccent; z: 0; y: 0
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

                width: 28; height: 28; radius: 8; z: 1
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
                  onEntered: root.showTooltip("workspace " + wsPill.modelData.id + "\nclick to focus, scroll to switch", bar.screen, parent.mapToItem(null, parent.width/2, 0).x + 6)
                  onExited: root.hideTooltip()
                }
              }
            }
          }
        }

        // weather
        Rectangle {
          id: weatherPill
          Layout.preferredWidth: weatherRow.implicitWidth + 20; Layout.preferredHeight: 28; radius: 8
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
              else { root.pomodoroPopoutScreen = null; root.weatherPopoutScreen = root.weatherPopoutScreen === bar.screen ? null : bar.screen; }
            }
            onEntered: root.showTooltip(root.weatherError !== "" ? "weather\nclick to retry" : "weather\nclick for details", bar.screen, parent.mapToItem(null, parent.width/2, 0).x + 6)
            onExited: root.hideTooltip()
          }
        }

        // pomodoro
        Rectangle {
          id: pomPill
          Layout.preferredWidth: pomRow.implicitWidth + 20; Layout.preferredHeight: 28; radius: 8
          color: pomMouse.containsMouse ? Qt.rgba(root.colSurface0.r, root.colSurface0.g, root.colSurface0.b, 0.4) : "transparent"
          scale: pomMouse.containsMouse ? 1.02 : 1.0
          Behavior on scale { NumberAnimation { duration: 150 } }
          Behavior on color { ColorAnimation { duration: 200 } }
          RowLayout { id: pomRow; anchors.centerIn: parent; spacing: 4
            Text {
              text: "timer"
              font.family: root.iconFont; font.pixelSize: root.iconSize
              color: root.pomodoroActive ? root.colAccent : root.colSurface1
              Behavior on color { ColorAnimation { duration: 200 } }
            }
            Text {
              visible: root.pomodoroActive
              text: root.pomodoroText
              font.family: root.textFont; font.pixelSize: root.textSize; font.weight: Font.Bold
              color: root.colAccent
            }
          }
          MouseArea {
            id: pomMouse; hoverEnabled: true; anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked: mouse => {
              if (mouse.button === Qt.RightButton) root.stopPomodoro();
              else { root.weatherPopoutScreen = null; root.pomodoroPopoutScreen = root.pomodoroPopoutScreen === bar.screen ? null : bar.screen; }
            }
            onEntered: root.showTooltip("pomodoro - focus timer\nclick to open, right-click to stop", bar.screen, parent.mapToItem(null, parent.width/2, 0).x + 6)
            onExited: root.hideTooltip()
          }
        }

        // media visualizer
        Rectangle {
          visible: root.mediaActive
          Layout.preferredWidth: root.mediaActive ? cavaViz.width + 16 : 0
          Layout.preferredHeight: 28; radius: 8
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
              else if (root.activePlayer) root.activePlayer.togglePlaying();
            }
            onEntered: {
              let title = root.mediaArtist ? root.mediaArtist + " - " + root.mediaTitle : (root.mediaTitle || "media");
              root.showTooltip(title + "\n" + (root.mediaPlaying ? "playing" : "paused") + "\nclick to play/pause, right-click for mixer", bar.screen, parent.mapToItem(null, parent.width/2, 0).x + 6);
            }
            onExited: root.hideTooltip()
          }
        }
      }
    }

    Item { Layout.fillWidth: true }

    // right island
    Rectangle {
      id: rightIsland
      color: Qt.rgba(root.colBg.r, root.colBg.g, root.colBg.b, 0.75)
      radius: root.pillRadius + 2
      border.width: 1; border.color: Qt.rgba(root.colText.r, root.colText.g, root.colText.b, 0.05)
      Layout.preferredHeight: 40; Layout.preferredWidth: rightLayout.implicitWidth + 16
      Layout.maximumWidth: bar.width / 2 - clockBox.width / 2 - 16
      clip: true

      RowLayout {
        id: rightLayout; anchors.verticalCenter: parent.verticalCenter; anchors.right: parent.right; anchors.rightMargin: 8; spacing: 6

        // settings arrow, hover or click to reveal settings panel
        Rectangle {
          Layout.preferredWidth: 20; Layout.preferredHeight: 28; radius: 8
          color: arrowHover.hovered || bar.settingsOpen ? Qt.rgba(root.colSurface0.r, root.colSurface0.g, root.colSurface0.b, 0.4) : "transparent"
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
          MouseArea {
            anchors.fill: parent
            onClicked: { bar.settingsOpen = !bar.settingsOpen; if (!bar.settingsOpen) expandTimer.stop(); }
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
              color: root.micMuted ? Qt.rgba(root.colRed.r, root.colRed.g, root.colRed.b, 0.15) : (hovered ? Qt.rgba(root.colSurface1.r, root.colSurface1.g, root.colSurface1.b, 0.6) : Qt.rgba(root.colSurface0.r, root.colSurface0.g, root.colSurface0.b, 0.55))
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
                onEntered: { root.tooltipText = Qt.binding(() => "mic " + root.micVolPercent + "%" + (root.micMuted ? " (muted)" : "") + "\nscroll to adjust, click to mute\nright-click for settings"); root.tooltipScreen = bar.screen; root.tooltipX = parent.mapToItem(null, parent.width/2, 0).x + 6; root.tooltipVisible = false; tooltipTimer.restart(); }
                onExited: root.hideTooltip()
              }
            }

            // bluetooth
            Rectangle {
              property bool hovered: btMouse.containsMouse
              width: btRow.implicitWidth + 20; height: root.pillHeight; radius: root.pillRadius
              color: root.btOn ? Qt.rgba(root.colAccent.r, root.colAccent.g, root.colAccent.b, 0.2) : (hovered ? Qt.rgba(root.colSurface1.r, root.colSurface1.g, root.colSurface1.b, 0.6) : Qt.rgba(root.colSurface0.r, root.colSurface0.g, root.colSurface0.b, 0.55))
              Behavior on color { ColorAnimation { duration: 200 } }
              RowLayout { id: btRow; anchors.centerIn: parent; spacing: 6
                Text { text: root.btEnabled ? (root.btOn ? "bluetooth_connected" : "bluetooth") : "bluetooth_disabled"; font.family: root.iconFont; font.pixelSize: root.iconSize; color: root.btOn ? root.colAccent : root.colSubtext0 }
                Text { visible: root.btOn && root.btDevice !== ""; text: root.btDevice; font.family: root.textFont; font.pixelSize: root.textSize; color: root.colText; maximumLineCount: 1; Layout.maximumWidth: 100; elide: Text.ElideRight }
              }
              MouseArea {
                id: btMouse; hoverEnabled: true; anchors.fill: parent
                onClicked: Quickshell.execDetached([root.scripts.wezterm, "start", "--class", "bluetui", "--", "bluetui"])
                onEntered: root.showTooltip("bluetooth" + (root.btOn ? " - " + root.btDevice : "") + "\nclick to manage", bar.screen, parent.mapToItem(null, parent.width/2, 0).x + 6)
                onExited: root.hideTooltip()
              }
            }

            // wifi
            Rectangle {
              property bool hovered: wifiMouse.containsMouse
              width: wifiRow.implicitWidth + 20; height: root.pillHeight; radius: root.pillRadius
              color: root.wifiOn ? Qt.rgba(root.colBlue.r, root.colBlue.g, root.colBlue.b, 0.2) : (hovered ? Qt.rgba(root.colSurface1.r, root.colSurface1.g, root.colSurface1.b, 0.6) : Qt.rgba(root.colSurface0.r, root.colSurface0.g, root.colSurface0.b, 0.55))
              Behavior on color { ColorAnimation { duration: 200 } }
              RowLayout { id: wifiRow; anchors.centerIn: parent; spacing: 6
                Text { text: root.wifiIcon; font.family: root.iconFont; font.pixelSize: root.iconSize; color: root.wifiOn ? root.colBlue : root.colSubtext0 }
                Text { visible: root.wifiOn && root.wifiSsid !== ""; text: root.wifiSsid; font.family: root.textFont; font.pixelSize: root.textSize; color: root.colText; Layout.maximumWidth: 100; elide: Text.ElideRight }
                Text { visible: root.wifiOn && root.wifiSignal !== "0"; text: root.wifiSignal + "%"; font.family: root.textFont; font.pixelSize: 10; color: root.colSubtext0 }
                Text { visible: root.wifiOn && root.wifiIp !== ""; text: root.wifiIp; font.family: root.textFont; font.pixelSize: 10; color: root.colSubtext0 }
              }
              MouseArea {
                id: wifiMouse; hoverEnabled: true; anchors.fill: parent
                onClicked: Quickshell.execDetached([root.scripts.wezterm, "start", "--class", "wifi-tui", "--", root.scripts.wifiTui])
                onEntered: root.showTooltip("network\nclick to manage", bar.screen, parent.mapToItem(null, parent.width/2, 0).x + 6)
                onExited: root.hideTooltip()
              }
            }

            // volume
            Rectangle {
              property bool hovered: volMouse.containsMouse
              width: volRow.implicitWidth + 20; height: root.pillHeight; radius: root.pillRadius
              color: root.volMuted ? Qt.rgba(root.colRed.r, root.colRed.g, root.colRed.b, 0.15) : (hovered ? Qt.rgba(root.colSurface1.r, root.colSurface1.g, root.colSurface1.b, 0.6) : Qt.rgba(root.colSurface0.r, root.colSurface0.g, root.colSurface0.b, 0.55))
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
                onEntered: { root.tooltipText = Qt.binding(() => "vol " + root.volPercent + "%" + (root.volMuted ? " (muted)" : "") + "\nscroll to adjust, click to mute\nright-click for settings"); root.tooltipScreen = bar.screen; root.tooltipX = parent.mapToItem(null, parent.width/2, 0).x + 6; root.tooltipVisible = false; tooltipTimer.restart(); }
                onExited: root.hideTooltip()
              }
            }
          }
        }

        // caffeine
        Rectangle {
          Layout.preferredWidth: 28; Layout.preferredHeight: 28; radius: 8
          color: root.caffeineActive ? Qt.rgba(root.colGreen.r, root.colGreen.g, root.colGreen.b, 0.15) : (cafMouse.containsMouse ? Qt.rgba(root.colSurface0.r, root.colSurface0.g, root.colSurface0.b, 0.4) : "transparent")
          Behavior on color { ColorAnimation { duration: 150 } }
          Text { anchors.centerIn: parent; text: root.caffeineIcon; font.family: root.iconFont; font.pixelSize: root.iconSize; color: root.caffeineActive ? root.colGreen : root.colSurface1; Behavior on color { ColorAnimation { duration: 200 } } }
          MouseArea {
            id: cafMouse; hoverEnabled: true; anchors.fill: parent
            onClicked: Quickshell.execDetached(["bash", "-c", root.scripts.caffeine + " toggle"])
            onEntered: root.showTooltip("caffeine - disables screen locking\nclick to " + (root.caffeineActive ? "disable" : "enable"), bar.screen, parent.mapToItem(null, parent.width/2, 0).x + 6)
            onExited: root.hideTooltip()
          }
        }

        // recording
        Rectangle {
          visible: root.recording
          Layout.preferredWidth: root.recording ? recRow.implicitWidth + 16 : 0; Layout.preferredHeight: 28; radius: 8; color: "transparent"
          RowLayout { id: recRow; anchors.centerIn: parent; spacing: 4
            Text { text: "fiber_manual_record"; font.family: root.iconFont; font.pixelSize: root.iconSize; color: root.colRed }
            Text { text: "REC"; font.family: root.textFont; font.pixelSize: 11; font.weight: Font.Bold; color: root.colRed }
          }
        }

        // cpu + memory
        Rectangle {
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
            Text { text: "memory"; font.family: root.iconFont; font.pixelSize: root.iconSize; color: root.colText }
            Text { text: root.memPercent + "%"; Layout.preferredWidth: 26; horizontalAlignment: Text.AlignRight; font.family: root.textFont; font.pixelSize: root.textSize; font.weight: Font.Medium; color: root.colText }
          }
          MouseArea {
            id: sysMouse; hoverEnabled: true; anchors.fill: parent
            onClicked: Quickshell.execDetached([root.scripts.wezterm, "start", "--class", "btop", "--", "btop"])
            onEntered: root.showTooltip("system resources\nclick to open btop", bar.screen, parent.mapToItem(null, parent.width/2, 0).x + 6)
            onExited: root.hideTooltip()
          }
        }

        // battery
        Rectangle {
          id: batPill
          visible: root.hasBattery
          property bool hovered: batMouse.containsMouse
          Layout.preferredWidth: root.hasBattery ? batRow.implicitWidth + 20 : 0; Layout.preferredHeight: root.pillHeight; radius: root.pillRadius
          property color batColor: root.batCharging ? root.colGreen : (root.batPercent >= 70 ? root.colBlue : (root.batPercent >= 30 ? root.colYellow : root.colRed))
          color: (root.batCharging || root.batPercent <= 20)
            ? Qt.rgba(batPill.batColor.r, batPill.batColor.g, batPill.batColor.b, 0.2)
            : (hovered ? Qt.rgba(root.colSurface1.r, root.colSurface1.g, root.colSurface1.b, 0.6) : Qt.rgba(root.colSurface0.r, root.colSurface0.g, root.colSurface0.b, 0.55))
          scale: hovered ? 1.02 : 1.0
          Behavior on scale { NumberAnimation { duration: 150 } }
          Behavior on color { ColorAnimation { duration: 200 } }
          RowLayout { id: batRow; anchors.centerIn: parent; spacing: 6
            Text { text: root.batIcon; font.family: root.iconFont; font.pixelSize: root.iconSize; color: batPill.batColor }
            Text { text: root.batPercent + "%"; font.family: root.textFont; font.pixelSize: root.textSize; font.weight: Font.Medium; color: (root.batCharging || root.batPercent <= 20) ? batPill.batColor : root.colText }
          }
          MouseArea {
            id: batMouse; hoverEnabled: true; anchors.fill: parent
            onEntered: root.showTooltip("battery\n" + root.batPercent + "%" + (root.batCharging ? " charging" : ""), bar.screen, parent.mapToItem(null, parent.width/2, 0).x + 6)
            onExited: root.hideTooltip()
          }
        }

        // notifications
        Rectangle {
          Layout.preferredWidth: 28; Layout.preferredHeight: 28; radius: 8
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
            onClicked: { root.notifPanelOpen = !root.notifPanelOpen; if (root.notifPanelOpen) root.unreadCount = 0; }
            onEntered: root.showTooltip("notifications\nclick to open panel", bar.screen, parent.mapToItem(null, parent.width/2, 0).x + 6)
            onExited: root.hideTooltip()
          }
        }

        // lock indicators
        Rectangle {
          visible: root.capsLock; Layout.preferredWidth: root.capsLock ? 40 : 0; Layout.preferredHeight: 28; radius: 8
          color: Qt.rgba(root.colAccent.r, root.colAccent.g, root.colAccent.b, 0.15)
          Text { anchors.centerIn: parent; text: "CAP"; font.family: root.textFont; font.pixelSize: 10; font.weight: Font.Bold; color: root.colAccent }
        }
        Rectangle {
          visible: root.numLock; Layout.preferredWidth: root.numLock ? 40 : 0; Layout.preferredHeight: 28; radius: 8
          color: Qt.rgba(root.colAccent.r, root.colAccent.g, root.colAccent.b, 0.15)
          Text { anchors.centerIn: parent; text: "NUM"; font.family: root.textFont; font.pixelSize: 10; font.weight: Font.Bold; color: root.colAccent }
        }

        // tray
        Repeater {
          model: SystemTray.items
          delegate: Rectangle {
            id: trayDelegate
            required property SystemTrayItem modelData
            Layout.preferredWidth: 28; Layout.preferredHeight: 28; radius: 8
            color: trayMouse.containsMouse ? Qt.rgba(root.colSurface1.r, root.colSurface1.g, root.colSurface1.b, 0.5) : "transparent"
            Behavior on color { ColorAnimation { duration: 150 } }
            Image { anchors.centerIn: parent; source: trayDelegate.modelData.icon ?? ""; width: 18; height: 18; sourceSize.width: 18; sourceSize.height: 18 }
            QsMenuAnchor {
              id: menuAnchor
              menu: trayDelegate.modelData.menu
              anchor.window: bar
              anchor.adjustment: PopupAdjustment.Flip
            }
            MouseArea {
              id: trayMouse; hoverEnabled: true; anchors.fill: parent
              acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
              onClicked: mouse => {
                if (mouse.button === Qt.RightButton || trayDelegate.modelData.onlyMenu) {
                  if (trayDelegate.modelData.hasMenu) menuAnchor.open();
                } else if (mouse.button === Qt.LeftButton) {
                  trayDelegate.modelData.activate();
                } else if (mouse.button === Qt.MiddleButton) {
                  trayDelegate.modelData.secondaryActivate();
                }
              }
            }
          }
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

  // pomodoro popout
  PopupWindow {
    id: pomPopout
    visible: root.pomodoroPopoutScreen === bar.screen
    anchor.window: bar
    anchor.rect: {
      let mapped = pomPill.mapToItem(null, 0, 0);
      return Qt.rect(mapped.x, 0, pomPill.width, bar.implicitHeight);
    }
    anchor.edges: Edges.Bottom
    anchor.gravity: Edges.Bottom
    anchor.adjustment: PopupAdjustment.SlideX
    implicitWidth: 400
    implicitHeight: pomCol.implicitHeight + 36
    color: "transparent"

    HyprlandFocusGrab {
      active: root.pomodoroPopoutScreen === bar.screen
      windows: [pomPopout, bar]
      onCleared: root.pomodoroPopoutScreen = null
    }

    onVisibleChanged: {
      if (visible && !root.pomodoroActive)
        pomTaskInput.forceActiveFocus();
    }

    Rectangle {
      anchors.fill: parent; radius: 14
      color: root.colBg
      border.width: 1; border.color: Qt.rgba(root.colText.r, root.colText.g, root.colText.b, 0.08)

      Column {
        id: pomCol
        anchors { fill: parent; margins: 16 }
        spacing: 12

        Text { text: "Pomodoro"; font.family: root.textFont; font.pixelSize: 15; font.weight: Font.Bold; color: root.colText }

        Column {
          visible: root.pomodoroActive
          width: parent.width; spacing: 10

          Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: {
              let remaining = Math.max(0, root.pomodoroEndTime - clock.date.getTime() / 1000);
              let min = Math.floor(remaining / 60);
              let sec = Math.floor(remaining % 60);
              return String(min).padStart(2, '0') + ":" + String(sec).padStart(2, '0');
            }
            font.family: root.textFont; font.pixelSize: 40; color: root.colAccent
          }

          Text {
            anchors.horizontalCenter: parent.horizontalCenter; text: root.pomodoroTask
            font.family: root.textFont; font.pixelSize: 13; color: root.colSubtext0
            width: parent.width; elide: Text.ElideRight; horizontalAlignment: Text.AlignHCenter
          }

          Rectangle {
            width: parent.width; height: 6; radius: 3; color: root.colSurface0
            Rectangle {
              height: parent.height; radius: 3; color: root.colAccent
              width: { let elapsed = 1500 - Math.max(0, root.pomodoroEndTime - clock.date.getTime() / 1000); return parent.width * Math.min(1, elapsed / 1500); }
              Behavior on width { NumberAnimation { duration: 1000 } }
            }
          }

          Rectangle {
            width: parent.width; height: 40; radius: 20
            color: stopMouse.containsMouse ? Qt.rgba(root.colRed.r, root.colRed.g, root.colRed.b, 0.25) : Qt.rgba(root.colRed.r, root.colRed.g, root.colRed.b, 0.15)
            Behavior on color { ColorAnimation { duration: 150 } }
            Text { anchors.centerIn: parent; text: "Stop"; font.family: root.textFont; font.pixelSize: 13; color: root.colRed }
            MouseArea { id: stopMouse; anchors.fill: parent; hoverEnabled: true; onClicked: { root.stopPomodoro(); root.pomodoroPopoutScreen = null; } }
          }
        }

        Column {
          visible: !root.pomodoroActive
          width: parent.width; spacing: 10

          Rectangle {
            width: parent.width; height: 40; radius: 20
            color: Qt.rgba(root.colSurface0.r, root.colSurface0.g, root.colSurface0.b, 0.6)

            TextInput {
              id: pomTaskInput
              anchors { fill: parent; leftMargin: 16; rightMargin: 16 }
              verticalAlignment: TextInput.AlignVCenter
              font.family: root.textFont; font.pixelSize: 13; color: root.colText
              selectionColor: root.colAccent; clip: true

              Text {
                anchors.fill: parent; verticalAlignment: Text.AlignVCenter
                text: "what are you working on?"
                font.family: root.textFont; font.pixelSize: 13; color: root.colSurface1
                visible: pomTaskInput.text === ""
              }

              Keys.onReturnPressed: {
                if (pomTaskInput.text.trim() !== "") { root.startPomodoro(pomTaskInput.text.trim()); pomTaskInput.text = ""; }
              }
              Keys.onEscapePressed: root.pomodoroPopoutScreen = null
            }
          }

          Rectangle {
            width: parent.width; height: 40; radius: 20
            color: startMouse.containsMouse ? Qt.rgba(root.colAccent.r, root.colAccent.g, root.colAccent.b, 0.25) : Qt.rgba(root.colAccent.r, root.colAccent.g, root.colAccent.b, 0.15)
            Behavior on color { ColorAnimation { duration: 150 } }
            Text { anchors.centerIn: parent; text: "Start (25 min)"; font.family: root.textFont; font.pixelSize: 13; color: root.colAccent }
            MouseArea {
              id: startMouse; anchors.fill: parent; hoverEnabled: true
              onClicked: { if (pomTaskInput.text.trim() !== "") { root.startPomodoro(pomTaskInput.text.trim()); pomTaskInput.text = ""; } }
            }
          }

          Column {
            visible: root.pomodoroRecent.length > 0
            width: parent.width; spacing: 4

            Rectangle { width: parent.width; height: 1; color: Qt.rgba(root.colSurface0.r, root.colSurface0.g, root.colSurface0.b, 0.5) }
            Text { text: "Recent"; font.family: root.textFont; font.pixelSize: 11; color: root.colSurface1; topPadding: 4 }

            Repeater {
              model: root.pomodoroRecent.slice(0, 8)
              delegate: Rectangle {
                required property var modelData
                property bool hovered: recentMouse.containsMouse || delMouse.containsMouse
                width: parent.width; height: 32; radius: 8
                color: hovered ? Qt.rgba(root.colSurface0.r, root.colSurface0.g, root.colSurface0.b, 0.4) : "transparent"
                Behavior on color { ColorAnimation { duration: 100 } }

                MouseArea {
                  id: recentMouse; anchors.fill: parent; hoverEnabled: true
                  onClicked: root.startPomodoro(modelData)
                }

                Text {
                  anchors { left: parent.left; right: delBtn.left; top: parent.top; bottom: parent.bottom; leftMargin: 10; rightMargin: 4 }
                  verticalAlignment: Text.AlignVCenter
                  text: modelData; font.family: root.textFont; font.pixelSize: 12; color: root.colSubtext0
                  elide: Text.ElideRight
                }

                Rectangle {
                  id: delBtn
                  anchors { right: parent.right; verticalCenter: parent.verticalCenter; rightMargin: 6 }
                  width: 20; height: 20; radius: 10
                  visible: hovered
                  color: delMouse.containsMouse ? Qt.rgba(root.colRed.r, root.colRed.g, root.colRed.b, 0.2) : "transparent"
                  Behavior on color { ColorAnimation { duration: 100 } }
                  Text { anchors.centerIn: parent; text: "close"; font.family: root.iconFont; font.pixelSize: 14; color: delMouse.containsMouse ? root.colRed : root.colSurface1; Behavior on color { ColorAnimation { duration: 100 } } }
                  MouseArea { id: delMouse; anchors.fill: parent; hoverEnabled: true; onClicked: root.removeRecentPomodoro(modelData) }
                }
              }
            }
          }
        }
      }
    }
  }

}
