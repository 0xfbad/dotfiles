import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

PanelWindow {
  id: wallpickerWin
  visible: root.wallpickerOpen
  anchors { top: true; bottom: true; left: true; right: true }
  exclusiveZone: 0
  color: Qt.rgba(0, 0, 0, 0.7)

  HyprlandFocusGrab {
    active: root.wallpickerOpen
    windows: [wallpickerWin]
    onCleared: root.wallpickerOpen = false
  }

  MouseArea { anchors.fill: parent; onClicked: root.wallpickerOpen = false }

  Rectangle {
    anchors.centerIn: parent
    width: Math.min(parent.width - 60, 1100)
    height: Math.min(parent.height - 60, 750)
    radius: 16
    color: Qt.rgba(root.colBg.r, root.colBg.g, root.colBg.b, 0.95)
    border.width: 1; border.color: Qt.rgba(root.colText.r, root.colText.g, root.colText.b, 0.08)
    clip: true

    // prevent click-through to backdrop dismisser
    MouseArea { anchors.fill: parent }

    Column {
      anchors.fill: parent; anchors.margins: 16; spacing: 12

      RowLayout {
        width: parent.width
        Text { text: "Wallpapers"; font.family: root.textFont; font.pixelSize: 16; font.weight: Font.Bold; color: root.colText; Layout.fillWidth: true }
        Text { text: root.wallpaperList.length + " found"; font.family: root.textFont; font.pixelSize: 11; color: root.colSurface1 }
      }

      GridView {
        id: wallGrid
        width: parent.width
        height: parent.height - 36
        model: root.wallpaperList
        cellWidth: Math.floor(width / Math.max(1, Math.floor(width / 200)))
        cellHeight: 140
        clip: true
        cacheBuffer: 400

        delegate: Item {
          required property var modelData
          required property int index
          width: wallGrid.cellWidth; height: 140

          Rectangle {
            anchors.fill: parent; anchors.margins: 4
            radius: 10; clip: true
            color: root.colSurface0
            border.width: wpMouse.containsMouse ? 2 : 0
            border.color: root.colAccent
            scale: wpMouse.containsMouse ? 1.03 : 1.0
            Behavior on scale { NumberAnimation { duration: 150 } }

            Image {
              anchors.fill: parent
              source: "file://" + modelData
              fillMode: Image.PreserveAspectCrop
              asynchronous: true
              sourceSize.width: 400; sourceSize.height: 280
            }

            Rectangle {
              anchors.bottom: parent.bottom; width: parent.width; height: 26
              color: Qt.rgba(0, 0, 0, 0.7)
              Text {
                anchors.centerIn: parent
                text: {
                  let p = modelData.split("/");
                  let n = p[p.length - 1];
                  let d = n.lastIndexOf(".");
                  return d > 0 ? n.substring(0, d) : n;
                }
                font.family: root.textFont; font.pixelSize: 10; color: root.colText
              }
            }

            MouseArea {
              id: wpMouse; anchors.fill: parent; hoverEnabled: true
              onClicked: {
                Quickshell.execDetached([root.scripts.swww || "swww", "img",
                  "--transition-type", "grow",
                  "--transition-pos", "0.5,0.5",
                  "--transition-duration", "1",
                  modelData]);
                root.wallpickerOpen = false;
              }
            }
          }
        }
      }
    }
  }
}
