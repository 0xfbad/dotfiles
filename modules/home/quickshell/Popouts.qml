import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

Item {
    function windDir(d) {
    let m = {"N":"North","NNE":"North Northeast","NE":"Northeast","ENE":"East Northeast","E":"East","ESE":"East Southeast","SE":"Southeast","SSE":"South Southeast","S":"South","SSW":"South Southwest","SW":"Southwest","WSW":"West Southwest","W":"West","WNW":"West Northwest","NW":"Northwest","NNW":"North Northwest"};
    return m[d] || d;
  }

  // weather
  PanelWindow {
    id: weatherPopout
    visible: root.weatherPopoutOpen
    anchors { top: true; left: true }
    margins { top: 42; left: 10 }
    exclusiveZone: -1
    implicitWidth: 400
    implicitHeight: weatherCol.implicitHeight + 36
    color: "transparent"

    HyprlandFocusGrab {
      active: root.weatherPopoutOpen
      windows: [weatherPopout]
      onCleared: root.weatherPopoutOpen = false
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
          Text {
            visible: root.weatherLastUpdated !== ""
            text: "updated " + root.weatherLastUpdated; font.family: root.textFont; font.pixelSize: 10; color: root.colSurface1
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
              if (parts.length >= 3) return parts[0] + " mph " + windDir(parts[2]);
              return root.weatherWind;
            }
            font.family: root.textFont; font.pixelSize: 13; color: root.colText
          }
          Text { visible: root.weatherRain !== ""; text: "Rain"; font.family: root.textFont; font.pixelSize: 13; color: root.colSubtext0 }
          Text { visible: root.weatherRain !== ""; text: root.weatherRain; font.family: root.textFont; font.pixelSize: 13; color: root.colText }
        }

        // forecast
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
              Text { anchors.horizontalCenter: parent.horizontalCenter; text: modelData.temp + "°"; font.family: root.textFont; font.pixelSize: 13; color: root.colText }
            }
          }

                    Rectangle { visible: root.weatherTomorrow !== null; Layout.preferredWidth: 1; Layout.preferredHeight: 50; color: Qt.rgba(root.colSurface1.r, root.colSurface1.g, root.colSurface1.b, 0.3) }

                    Column {
            visible: root.weatherTomorrow !== null
            Layout.fillWidth: true; spacing: 4
            Text { anchors.horizontalCenter: parent.horizontalCenter; text: "Tomorrow"; font.family: root.textFont; font.pixelSize: 11; color: root.colSubtext0 }
            Text { anchors.horizontalCenter: parent.horizontalCenter; text: root.weatherTomorrow?.icon ?? ""; font.family: root.iconFont; font.pixelSize: 22; color: root.colYellow }
            Text { anchors.horizontalCenter: parent.horizontalCenter; text: (root.weatherTomorrow?.high ?? "") + "°/" + (root.weatherTomorrow?.low ?? "") + "°"; font.family: root.textFont; font.pixelSize: 12; color: root.colText }
          }
        }
      }
    }
  }

  // pomodoro
  PanelWindow {
    id: pomPopout
    visible: root.pomodoroPopoutOpen
    anchors { top: true; left: true }
    margins { top: 42; left: 200 }
    exclusiveZone: -1
    implicitWidth: 400
    implicitHeight: pomCol.implicitHeight + 36
    color: "transparent"

    HyprlandFocusGrab {
      active: root.pomodoroPopoutOpen
      windows: [pomPopout]
      onCleared: root.pomodoroPopoutOpen = false
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
            MouseArea { id: stopMouse; anchors.fill: parent; hoverEnabled: true; onClicked: { root.stopPomodoro(); root.pomodoroPopoutOpen = false; } }
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
              Keys.onEscapePressed: root.pomodoroPopoutOpen = false
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

          // recent tasks
          Column {
            visible: root.pomodoroRecent.length > 0
            width: parent.width; spacing: 4

            Rectangle { width: parent.width; height: 1; color: Qt.rgba(root.colSurface0.r, root.colSurface0.g, root.colSurface0.b, 0.5) }
            Text { text: "Recent"; font.family: root.textFont; font.pixelSize: 11; color: root.colSurface1; topPadding: 4 }

            Repeater {
              model: root.pomodoroRecent.slice(0, 8)
              delegate: Rectangle {
                required property var modelData
                width: parent.width; height: 32; radius: 8
                color: recentMouse.containsMouse ? Qt.rgba(root.colSurface0.r, root.colSurface0.g, root.colSurface0.b, 0.4) : "transparent"
                Behavior on color { ColorAnimation { duration: 100 } }
                Text {
                  anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
                  verticalAlignment: Text.AlignVCenter
                  text: modelData; font.family: root.textFont; font.pixelSize: 12; color: root.colSubtext0
                  elide: Text.ElideRight
                }
                MouseArea { id: recentMouse; anchors.fill: parent; hoverEnabled: true; onClicked: root.startPomodoro(modelData) }
              }
            }
          }
        }
      }
    }
  }
}
