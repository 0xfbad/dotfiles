import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

PanelWindow {
  id: cheatWin
  visible: root.cheatsheetOpen
  focusable: true
  anchors { top: true; bottom: true; left: true; right: true }
  exclusiveZone: -1
  color: Qt.rgba(0, 0, 0, 0.65)
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

  HyprlandFocusGrab {
    active: root.cheatsheetOpen
    windows: [cheatWin]
    onCleared: root.cheatsheetOpen = false
  }

  onVisibleChanged: { if (visible) keyCapture.forceActiveFocus(); }

  MouseArea { anchors.fill: parent; onClicked: root.cheatsheetOpen = false }

  property var actionKeys: [
    { key: "v", icon: "volume_up", desc: "volume mixer", cmd: root.scripts.pavucontrol || "pavucontrol" },
    { key: "n", icon: "folder", desc: "file manager", cmd: "dolphin" },
    { key: "b", icon: "bluetooth", desc: "bluetooth", cmd: (root.scripts.wezterm || "wezterm") + " start -- bluetui" },
    { key: "w", icon: "wifi", desc: "wifi", cmd: (root.scripts.wezterm || "wezterm") + " start --class wifi-tui -- " + (root.scripts.wifiTui || "wlctl") },
    { key: "d", icon: "deployed_code", desc: "docker", cmd: (root.scripts.wezterm || "wezterm") + " start -- lazydocker" },
    { key: "m", icon: "monitor", desc: "monitor config", cmd: (root.scripts.wezterm || "wezterm") + " start -- hyprmon" },
    { key: "e", icon: "edit", desc: "edit clipboard", cmd: "wl-paste | satty -f -" },
  ]

  property var refCategories: [
    { name: "Windows", binds: [
      { keys: "Super  Enter", desc: "terminal" },
      { keys: "Super  W", desc: "close" },
      { keys: "Super  F", desc: "fullscreen" },
      { keys: "Super  T", desc: "float" },
      { keys: "Super  J", desc: "toggle split" },
      { keys: "Super  O", desc: "pop out" },
      { keys: "Super  C", desc: "center" },
    ]},
    { name: "Focus", binds: [
      { keys: "Super  Arrows", desc: "navigate" },
      { keys: "Super  H/K/L", desc: "navigate" },
      { keys: "Super  Shift  Arrows", desc: "swap" },
      { keys: "Super  Ctrl  H/J/K/L", desc: "resize" },
    ]},
    { name: "Workspaces", binds: [
      { keys: "Super  1-0", desc: "switch" },
      { keys: "Super  Shift  1-0", desc: "move window" },
      { keys: "Super  Tab", desc: "next workspace" },
      { keys: "Super  Shift  Tab", desc: "previous" },
      { keys: "Alt  Tab", desc: "cycle windows" },
      { keys: "Super  S", desc: "scratchpad" },
    ]},
    { name: "Scrolling", binds: [
      { keys: "Super  [ ]", desc: "scroll viewport" },
      { keys: "Super  Shift  [ ]", desc: "swap columns" },
      { keys: "Super  Ctrl  +/-", desc: "resize column" },
      { keys: "Super  Alt  +/-", desc: "preset width" },
      { keys: "Super  Home/End", desc: "first/last" },
    ]},
    { name: "Capture", binds: [
      { keys: "Print", desc: "screenshot region" },
      { keys: "Super  Shift  S", desc: "screenshot + edit" },
      { keys: "Super  Ctrl  S", desc: "screenshot full" },
      { keys: "Super  Shift  E", desc: "edit clipboard" },
      { keys: "Super  Shift  R", desc: "record toggle" },
    ]},
    { name: "System", binds: [
      { keys: "Super  Space", desc: "launcher" },
      { keys: "Super  D", desc: "which-key" },
      { keys: "Super  Ctrl  V", desc: "clipboard" },
      { keys: "Super  Ctrl  L", desc: "lock screen" },
      { keys: "Super  Escape", desc: "power menu" },
      { keys: "Super  \\", desc: "toggle layout" },
      { keys: "Super  V", desc: "mic mute" },
      { keys: "Super  N", desc: "notifications" },
    ]},
  ]

  // invisible focus target for key capture
  Item {
    id: keyCapture
    focus: true
    Keys.onPressed: event => {
      if (event.key === Qt.Key_Escape) { root.cheatsheetOpen = false; event.accepted = true; return; }
      let keyStr = event.text.toLowerCase();
      let action = cheatWin.actionKeys.find(a => a.key === keyStr);
      if (action) {
        let cmd = action.cmd;
        root.cheatsheetOpen = false;
        // delay exec so the overlay hides first (important for screenshot tools)
        Qt.callLater(() => { Quickshell.execDetached(["bash", "-c", cmd]); });
        event.accepted = true;
      }
    }
  }

  // center panel, sized relative to screen
  Rectangle {
    anchors.centerIn: parent
    width: parent.width * 0.75
    height: Math.min(parent.height * 0.8, contentCol.implicitHeight + 48)
    radius: 16
    color: Qt.rgba(root.colBg.r, root.colBg.g, root.colBg.b, 0.95)
    border.width: 1; border.color: Qt.rgba(root.colText.r, root.colText.g, root.colText.b, 0.08)

    MouseArea { anchors.fill: parent }

    Flickable {
      anchors { fill: parent; margins: 24 }
      contentHeight: contentCol.implicitHeight
      clip: true
      boundsBehavior: Flickable.StopAtBounds

      Column {
        id: contentCol
        width: parent.width; spacing: 18

        // header
        RowLayout {
          width: parent.width
          Text { text: "Keybinds"; font.family: root.textFont; font.pixelSize: 22; font.weight: Font.Bold; color: root.colText }
          Item { Layout.fillWidth: true }
          Text { text: "press a key to execute"; font.family: root.textFont; font.pixelSize: 13; color: root.colSurface1 }
          Text { text: "Esc to close"; font.family: root.textFont; font.pixelSize: 13; color: root.colSurface1; leftPadding: 12 }
        }

        // quick actions
        Text { text: "Quick Actions"; font.family: root.textFont; font.pixelSize: 16; font.weight: Font.Bold; color: root.colAccent }

        Flow {
          width: parent.width; spacing: 10

          Repeater {
            model: cheatWin.actionKeys
            Rectangle {
              required property var modelData
              required property int index
              width: actionItemRow.implicitWidth + 20; height: 40; radius: 10
              color: actionItemMouse.containsMouse ? Qt.rgba(root.colAccent.r, root.colAccent.g, root.colAccent.b, 0.2) : Qt.rgba(root.colSurface0.r, root.colSurface0.g, root.colSurface0.b, 0.5)
              Behavior on color { ColorAnimation { duration: 100 } }

              RowLayout {
                id: actionItemRow; anchors.centerIn: parent; spacing: 8

                // beveled key
                Rectangle {
                  width: keyLbl.implicitWidth + 16; height: 28; radius: 6
                  color: root.colSurface0

                  Rectangle {
                    anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                    height: 3; radius: 3; color: root.colSurface1; opacity: 0.5
                  }

                  Text {
                    id: keyLbl; anchors.centerIn: parent
                    text: modelData.key.toUpperCase()
                    font.family: root.textFont; font.pixelSize: 14; font.weight: Font.Bold; color: root.colAccent
                  }
                }

                Text { text: modelData.icon; font.family: root.iconFont; font.pixelSize: 18; color: root.colSubtext0 }
                Text { text: modelData.desc; font.family: root.textFont; font.pixelSize: 14; color: root.colSubtext0 }
              }

              MouseArea {
                id: actionItemMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                onClicked: {
                  let cmd = modelData.cmd;
                  root.cheatsheetOpen = false;
                  Qt.callLater(() => { Quickshell.execDetached(["bash", "-c", cmd]); });
                }
              }
            }
          }
        }

        Rectangle { width: parent.width; height: 1; color: Qt.rgba(root.colSurface0.r, root.colSurface0.g, root.colSurface0.b, 0.5) }

        // reference keybinds
        Text { text: "All Keybinds"; font.family: root.textFont; font.pixelSize: 16; font.weight: Font.Bold; color: root.colText }

        GridLayout {
          width: parent.width; columns: 3; columnSpacing: 20; rowSpacing: 20

          Repeater {
            model: cheatWin.refCategories

            Column {
              required property var modelData
              Layout.preferredWidth: (parent.width - 40) / 3; spacing: 7

              Text { text: modelData.name; font.family: root.textFont; font.pixelSize: 15; font.weight: Font.Bold; color: root.colAccent; bottomPadding: 4 }

              Repeater {
                model: modelData.binds

                RowLayout {
                  required property var modelData
                  width: parent.width; spacing: 10

                  // key combo display
                  Row {
                    spacing: 4
                    Repeater {
                      model: modelData.keys.split("  ")
                      Rectangle {
                        required property var modelData
                        width: keyComboText.implicitWidth + 12; height: 22; radius: 5
                        color: root.colSurface0

                        Rectangle {
                          anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                          height: 2; radius: 2; color: root.colSurface1; opacity: 0.4
                        }

                        Text {
                          id: keyComboText; anchors.centerIn: parent
                          text: modelData
                          font.family: root.textFont; font.pixelSize: 12; color: root.colText
                        }
                      }
                    }
                  }

                  Text {
                    text: modelData.desc
                    font.family: root.textFont; font.pixelSize: 13; color: root.colSubtext0
                    Layout.fillWidth: true
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
