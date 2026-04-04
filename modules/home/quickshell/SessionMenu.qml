import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

PanelWindow {
  id: sessionWin
  visible: root.sessionOpen
  anchors { top: true; bottom: true; left: true; right: true }
  exclusiveZone: 0
  color: Qt.rgba(0, 0, 0, 0.6)

  HyprlandFocusGrab {
    active: root.sessionOpen
    windows: [sessionWin]
    onCleared: root.sessionOpen = false
  }

  MouseArea { anchors.fill: parent; onClicked: root.sessionOpen = false }

  Rectangle {
    anchors.centerIn: parent
    width: sessionRow.implicitWidth + 40; height: 100; radius: 16
    color: Qt.rgba(root.colBg.r, root.colBg.g, root.colBg.b, 0.95)
    border.width: 1; border.color: Qt.rgba(root.colText.r, root.colText.g, root.colText.b, 0.08)

    Row {
      id: sessionRow
      anchors.centerIn: parent; spacing: 16

      Repeater {
        model: [
          { icon: "󰌾", label: "Lock", cmd: "hyprlock" },
          { icon: "󰤄", label: "Suspend", cmd: "systemctl suspend" },
          { icon: "󰍃", label: "Logout", cmd: "hyprctl dispatch exit" },
          { icon: "󰜉", label: "Reboot", cmd: "systemctl reboot" },
          { icon: "󰐥", label: "Shutdown", cmd: "systemctl poweroff" }
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
  }
}
