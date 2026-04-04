import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

Item {
  // toasts
  PanelWindow {
    visible: toastModel.count > 0
    anchors { top: true; right: true }
    margins { top: 42; right: 10 }
    exclusiveZone: -1
    implicitWidth: 400
    implicitHeight: toastColumn.implicitHeight + 20
    color: "transparent"

    Column {
      id: toastColumn
      anchors { fill: parent; margins: 10 }
      spacing: 8

      Repeater {
        model: toastModel
        delegate: Rectangle {
          required property var model
          required property int index

          width: 380; height: toastContent.implicitHeight + 20; radius: 12
          color: Qt.rgba(root.colBg.r, root.colBg.g, root.colBg.b, 0.92)
          border.width: 2
          border.color: model.urgency === 2 ? root.colRed : Qt.rgba(root.colAccent.r, root.colAccent.g, root.colAccent.b, 0.3)

          Column {
            id: toastContent
            anchors { left: parent.left; right: closeBtn.left; top: parent.top; margins: 10 }
            spacing: 2

            Text { text: model.appName; font.family: root.textFont; font.pixelSize: 10; color: root.colSubtext0; visible: model.appName !== "" }
            Text { text: model.summary; font.family: root.textFont; font.pixelSize: 12; font.weight: Font.Bold; color: root.colText; width: parent.width; elide: Text.ElideRight }
            Text { text: model.body; font.family: root.textFont; font.pixelSize: 11; color: root.colSubtext0; width: parent.width; wrapMode: Text.WordWrap; maximumLineCount: 3; elide: Text.ElideRight; visible: model.body !== "" }
          }

          Rectangle {
            id: closeBtn
            anchors { right: parent.right; top: parent.top; margins: 8 }
            width: 20; height: 20; radius: 10
            color: closeMouse.containsMouse ? Qt.rgba(root.colRed.r, root.colRed.g, root.colRed.b, 0.2) : "transparent"
            Text { anchors.centerIn: parent; text: "󰅖"; font.family: root.iconFont; font.pixelSize: 12; color: root.colSubtext0 }
            MouseArea { id: closeMouse; hoverEnabled: true; anchors.fill: parent; onClicked: toastModel.remove(index) }
          }
        }
      }
    }
  }

  // history panel
  PanelWindow {
    id: notifPanelWin
    visible: root.notifPanelOpen
    anchors { top: true; right: true }
    margins { top: 42; right: 10 }
    exclusiveZone: -1
    implicitWidth: 420
    implicitHeight: Math.min(600, notifContent.implicitHeight + 20)
    color: "transparent"

    HyprlandFocusGrab {
      active: root.notifPanelOpen
      windows: [notifPanelWin]
      onCleared: root.notifPanelOpen = false
    }

    Rectangle {
      anchors.fill: parent; radius: 14
      color: root.colBg
      border.width: 1; border.color: Qt.rgba(root.colText.r, root.colText.g, root.colText.b, 0.08)

      Column {
        id: notifContent
        anchors { fill: parent; margins: 12 }
        spacing: 8

        RowLayout {
          width: parent.width
          Text { text: "Notifications"; font.family: root.textFont; font.pixelSize: 14; font.weight: Font.Bold; color: root.colText; Layout.fillWidth: true }
          Rectangle {
            width: clearText.implicitWidth + 16; height: 24; radius: 12
            color: clearMouse.containsMouse ? Qt.rgba(root.colRed.r, root.colRed.g, root.colRed.b, 0.15) : "transparent"
            Text { id: clearText; anchors.centerIn: parent; text: "Clear all"; font.family: root.textFont; font.pixelSize: 11; color: root.colSubtext0 }
            MouseArea { id: clearMouse; hoverEnabled: true; anchors.fill: parent; onClicked: { notifHistory.clear(); root.notifPanelOpen = false; } }
          }
        }

        Text {
          visible: notifHistory.count === 0
          text: "No notifications"; font.family: root.textFont; font.pixelSize: 12; color: root.colSurface1
          anchors.horizontalCenter: parent.horizontalCenter; topPadding: 40; bottomPadding: 40
        }

        ListView {
          width: parent.width; height: Math.min(400, contentHeight)
          model: notifHistory; clip: true; spacing: 6

          delegate: Rectangle {
            required property var model
            required property int index
            width: parent ? parent.width : 0; height: hContent.implicitHeight + 16; radius: 10
            color: Qt.rgba(root.colSurface0.r, root.colSurface0.g, root.colSurface0.b, 0.5)

            Column {
              id: hContent
              anchors { left: parent.left; right: hClose.left; top: parent.top; margins: 8 }
              spacing: 2
              RowLayout {
                width: parent.width
                Text { text: model.appName; font.family: root.textFont; font.pixelSize: 10; color: root.colSubtext0; Layout.fillWidth: true; elide: Text.ElideRight }
                Text { text: model.ts; font.family: root.textFont; font.pixelSize: 9; color: root.colSurface1 }
              }
              Text { text: model.summary; font.family: root.textFont; font.pixelSize: 11; font.weight: Font.Bold; color: root.colText; width: parent.width; elide: Text.ElideRight }
              Text { text: model.body; font.family: root.textFont; font.pixelSize: 10; color: root.colSubtext0; width: parent.width; wrapMode: Text.WordWrap; maximumLineCount: 2; elide: Text.ElideRight; visible: model.body !== "" }
            }
            Rectangle {
              id: hClose; anchors { right: parent.right; top: parent.top; margins: 6 }
              width: 18; height: 18; radius: 9
              color: hcMouse.containsMouse ? Qt.rgba(root.colRed.r, root.colRed.g, root.colRed.b, 0.2) : "transparent"
              Text { anchors.centerIn: parent; text: "󰅖"; font.family: root.iconFont; font.pixelSize: 10; color: root.colSurface1 }
              MouseArea { id: hcMouse; hoverEnabled: true; anchors.fill: parent; onClicked: notifHistory.remove(index) }
            }
          }
        }
      }
    }
  }
}
