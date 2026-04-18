import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

Variants {
  model: Quickshell.screens

  PanelWindow {
    id: sessionWin
    required property var modelData
    screen: modelData
    visible: root.sessionOpen
    anchors { top: true; bottom: true; left: true; right: true }
    exclusiveZone: -1
    focusable: true
    color: Qt.rgba(0, 0, 0, 0.6)
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    property int countdown: 5

    Item {
      id: keyCapture
      focus: true
      Keys.onPressed: event => {
        if (event.key === Qt.Key_Escape) { root.sessionOpen = false; event.accepted = true; }
      }
    }

    MouseArea {
      anchors.fill: parent
      hoverEnabled: true
      onPositionChanged: autoLockTimer.stop()
      onClicked: root.sessionOpen = false
    }

    Timer {
      id: autoLockTimer
      interval: 1000
      repeat: true
      onTriggered: {
        sessionWin.countdown--;
        if (sessionWin.countdown <= 0) {
          autoLockTimer.stop();
          root.sessionOpen = false;
          Quickshell.execDetached(["bash", "-c", "hyprlock"]);
        }
      }
    }

    onVisibleChanged: {
      if (visible) { sessionWin.countdown = 5; autoLockTimer.start(); keyCapture.forceActiveFocus(); }
      else autoLockTimer.stop();
    }

    Rectangle {
      anchors.centerIn: parent
      width: sessionRow.implicitWidth + 40; height: 100; radius: 16
      color: Qt.rgba(root.colBg.r, root.colBg.g, root.colBg.b, 0.95)
      border.width: 1; border.color: Qt.rgba(root.colText.r, root.colText.g, root.colText.b, 0.08)

      MouseArea { anchors.fill: parent; hoverEnabled: true; onPositionChanged: autoLockTimer.stop() }

      Row {
        id: sessionRow
        anchors.centerIn: parent; spacing: 16

        Repeater {
          model: [
            { icon: "lock", label: "Lock", cmd: "hyprlock" },
            { icon: "dark_mode", label: "Suspend", cmd: "systemctl suspend" },
            { icon: "logout", label: "Logout", cmd: "hyprctl dispatch exit" },
            { icon: "restart_alt", label: "Reboot", cmd: "systemctl reboot" },
            { icon: "power_settings_new", label: "Shutdown", cmd: "systemctl poweroff" }
          ]

          delegate: Rectangle {
            required property var modelData
            width: 64; height: 76; radius: 12
            color: sMouse.containsMouse ? Qt.rgba(root.colAccent.r, root.colAccent.g, root.colAccent.b, 0.2) : "transparent"
            Behavior on color { ColorAnimation { duration: 150 } }

            Column {
              anchors.centerIn: parent; spacing: 6
              Text { text: modelData.icon; font.family: root.iconFont; font.pixelSize: 24; color: sMouse.containsMouse ? root.colAccent : root.colText; anchors.horizontalCenter: parent.horizontalCenter; Behavior on color { ColorAnimation { duration: 150 } } }
              Text { text: modelData.label; font.family: root.textFont; font.pixelSize: 11; color: root.colSubtext0; anchors.horizontalCenter: parent.horizontalCenter }
            }

            MouseArea {
              id: sMouse; hoverEnabled: true; anchors.fill: parent
              onClicked: { root.sessionOpen = false; Quickshell.execDetached(["bash", "-c", modelData.cmd]); }
            }
          }
        }
      }

      Text {
        anchors { horizontalCenter: parent.horizontalCenter; top: parent.bottom; topMargin: 10 }
        visible: autoLockTimer.running
        text: "locking in " + sessionWin.countdown + "s"
        font.family: root.textFont; font.pixelSize: 12
        color: root.colSubtext0
      }
    }
  }
}
