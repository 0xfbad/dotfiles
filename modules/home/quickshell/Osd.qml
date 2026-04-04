import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

Variants {
  model: Quickshell.screens

  PanelWindow {
    required property var modelData
    screen: modelData

    visible: root.osdVisible
    anchors { bottom: true; left: true; right: true }
    margins { bottom: 60 }
    exclusiveZone: 0
    implicitHeight: 50
    color: "transparent"

    Rectangle {
      anchors.centerIn: parent
      width: 280; height: 44
      radius: root.pillRadius
      color: Qt.rgba(root.colBg.r, root.colBg.g, root.colBg.b, 0.9)
      border.width: 1; border.color: Qt.rgba(root.colText.r, root.colText.g, root.colText.b, 0.08)

      opacity: root.osdVisible ? 1 : 0
      scale: root.osdVisible ? 1 : 0.8
      Behavior on opacity { NumberAnimation { duration: 300 } }
      Behavior on scale { NumberAnimation { duration: 300 } }

      RowLayout {
        anchors.fill: parent; anchors.leftMargin: 14; anchors.rightMargin: 14; spacing: 12

        Text { text: root.osdIcon; font.family: root.iconFont; font.pixelSize: 18; color: root.colText }

        Rectangle {
          Layout.fillWidth: true; Layout.preferredHeight: 6; radius: 3; color: root.colSurface0
          Rectangle {
            width: parent.width * Math.max(0, Math.min(1, root.osdValue))
            height: parent.height; radius: 3; color: root.colAccent
            Behavior on width { NumberAnimation { duration: 150 } }
          }
        }

        Text { text: Math.round(root.osdValue * 100) + "%"; font.family: root.textFont; font.pixelSize: 11; font.weight: Font.Bold; color: root.colSubtext0; Layout.preferredWidth: 35; horizontalAlignment: Text.AlignRight }
      }
    }
  }
}
