import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Widgets

PanelWindow {
  id: launcherWin

  property bool showing: false
  visible: showing
  anchors { bottom: true; left: true; right: true }
  exclusiveZone: 0
  implicitHeight: searchCard.implicitHeight + 20
  color: "transparent"

  property real animProgress: 0

  Connections {
    target: root
    function onLauncherOpenChanged() {
      if (root.launcherOpen) {
        showing = true;
        animProgress = 0;
        openAnim.start();
        searchInput.text = "";
        searchInput.forceActiveFocus();
      } else {
        openAnim.stop();
        closeAnim.start();
      }
    }
  }

  NumberAnimation {
    id: openAnim; target: launcherWin; property: "animProgress"
    from: 0; to: 1; duration: 250
    easing.type: Easing.OutCubic
  }

  NumberAnimation {
    id: closeAnim; target: launcherWin; property: "animProgress"
    from: launcherWin.animProgress; to: 0; duration: 180
    easing.type: Easing.InCubic
    onFinished: launcherWin.showing = false
  }

  HyprlandFocusGrab {
    active: root.launcherOpen
    windows: [launcherWin]
    onCleared: root.launcherOpen = false
  }

  Rectangle {
    id: searchCard
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottom: parent.bottom
    anchors.bottomMargin: 10
    width: 650
    implicitHeight: cardColumn.implicitHeight + 24
    radius: 16
    color: root.colBg
    border.width: 1
    border.color: Qt.rgba(root.colAccent.r, root.colAccent.g, root.colAccent.b, 0.15)
    clip: true

    opacity: launcherWin.animProgress
    transform: Translate { y: (1 - launcherWin.animProgress) * 30 }

    // debounce avoids recomputing app list on every keystroke
    property string debouncedSearch: ""
    Timer {
      id: searchDebounce; interval: 80
      onTriggered: searchCard.debouncedSearch = root.launcherSearch
    }

    readonly property var apps: {
      let query = debouncedSearch.toLowerCase().trim();
      let all = DesktopEntries.applications.values.filter(e => !e.noDisplay);
      if (query === "") return all.slice(0, 12);

      let scored = [];
      for (let e of all) {
        let name = (e.name || "").toLowerCase();
        let kw = (e.keywords || []).join(" ").toLowerCase();
        let comment = (e.comment || "").toLowerCase();
        let score = 0;
        if (name === query) score = 200;
        else if (name.startsWith(query)) score = 100;
        else if (name.includes(query)) score = 80;
        else if (kw.includes(query)) score = 60;
        else if (comment.includes(query)) score = 40;
        else {
          let qi = 0;
          for (let c of name) { if (qi < query.length && c === query[qi]) qi++; }
          if (qi >= query.length) score = 20;
        }
        if (score > 0) scored.push({ entry: e, score: score });
      }
      scored.sort((a, b) => b.score - a.score);
      return scored.slice(0, 12).map(r => r.entry);
    }

    readonly property string calcResult: {
      if (!root.launcherSearch.startsWith("=")) return "";
      try {
        let expr = root.launcherSearch.substring(1).trim();
        if (expr === "") return "";
        return String(Function('"use strict"; return (' + expr + ')')());
      } catch(e) { return ""; }
    }

    Column {
      id: cardColumn
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.top: parent.top
      anchors.margins: 12
      spacing: 6

      ListView {
        id: appListView
        visible: searchCard.calcResult === "" && searchCard.apps.length > 0
        width: parent.width
        height: Math.min(420, contentHeight)
        model: searchCard.apps
        clip: true
        currentIndex: root.launcherIndex
        spacing: 2

        highlightFollowsCurrentItem: false
        highlight: Rectangle {
          radius: 10
          color: Qt.rgba(root.colAccent.r, root.colAccent.g, root.colAccent.b, 0.1)
          y: appListView.currentItem ? appListView.currentItem.y : 0
          width: appListView.width
          height: appListView.currentItem ? appListView.currentItem.height : 0
          Behavior on y { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        }

        delegate: Item {
          required property var modelData
          required property int index

          width: appListView.width
          height: 50

          Rectangle {
            anchors.fill: parent; radius: 10
            color: appMouse.containsMouse && index !== root.launcherIndex
              ? Qt.rgba(root.colSurface0.r, root.colSurface0.g, root.colSurface0.b, 0.3)
              : "transparent"
            Behavior on color { ColorAnimation { duration: 100 } }
          }

          Row {
            anchors.fill: parent
            anchors.leftMargin: 12; anchors.rightMargin: 12
            spacing: 12

            IconImage {
              anchors.verticalCenter: parent.verticalCenter
              source: Quickshell.iconPath(modelData.icon ?? "", "application-x-executable")
              implicitSize: 30
            }

            Column {
              anchors.verticalCenter: parent.verticalCenter
              width: parent.width - 54
              spacing: -1

              Text {
                text: modelData.name ?? ""
                font.family: root.textFont; font.pixelSize: 13; color: root.colText
                elide: Text.ElideRight; width: parent.width
              }
              Text {
                text: modelData.comment || modelData.genericName || ""
                font.family: root.textFont; font.pixelSize: 10; color: root.colSubtext0
                elide: Text.ElideRight; width: parent.width
                visible: text !== ""
              }
            }
          }

          MouseArea {
            id: appMouse; hoverEnabled: true; anchors.fill: parent
            onClicked: { modelData.execute(); root.launcherOpen = false; }
            onEntered: root.launcherIndex = index
          }
        }
      }

            Rectangle {
        visible: searchCard.calcResult !== ""
        width: parent.width; height: 50; radius: 10
        color: Qt.rgba(root.colAccent.r, root.colAccent.g, root.colAccent.b, 0.1)

        RowLayout {
          anchors.fill: parent; anchors.leftMargin: 14; anchors.rightMargin: 14; spacing: 10
          Text { text: "="; font.family: root.textFont; font.pixelSize: 18; font.weight: Font.Bold; color: root.colAccent }
          Text { text: searchCard.calcResult; font.family: root.textFont; font.pixelSize: 15; font.weight: Font.Bold; color: root.colText }
          Item { Layout.fillWidth: true }
          Text { text: "enter to copy"; font.family: root.textFont; font.pixelSize: 10; color: root.colSubtext0 }
        }
      }

            Rectangle {
        width: parent.width; height: 44; radius: 22
        color: Qt.rgba(root.colSurface0.r, root.colSurface0.g, root.colSurface0.b, 0.6)

        Row {
          anchors.fill: parent; anchors.leftMargin: 14; anchors.rightMargin: 14; spacing: 8

          Text {
            text: "search"; font.family: root.iconFont; font.pixelSize: 18
            color: root.colSubtext0; anchors.verticalCenter: parent.verticalCenter
          }

          TextInput {
            id: searchInput
            width: parent.width - 60
            anchors.verticalCenter: parent.verticalCenter
            font.family: root.textFont; font.pixelSize: 13
            color: root.colText; selectionColor: root.colAccent; clip: true

            onTextChanged: { root.launcherSearch = text; root.launcherIndex = 0; searchDebounce.restart(); }

            Text {
              anchors.fill: parent; verticalAlignment: Text.AlignVCenter
              text: "search apps, = for calc..."
              font.family: root.textFont; font.pixelSize: 13; color: root.colSurface1
              visible: searchInput.text === ""
            }

            Keys.onPressed: event => {
              if (event.key === Qt.Key_Escape) { root.launcherOpen = false; event.accepted = true; }
              else if (event.key === Qt.Key_Up) { root.launcherIndex = Math.max(root.launcherIndex - 1, 0); event.accepted = true; }
              else if (event.key === Qt.Key_Down) { root.launcherIndex = Math.min(root.launcherIndex + 1, appListView.count - 1); event.accepted = true; }
              else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                if (searchCard.calcResult !== "") Quickshell.execDetached(["wl-copy", searchCard.calcResult]);
                else if (searchCard.apps.length > 0 && root.launcherIndex < searchCard.apps.length) searchCard.apps[root.launcherIndex].execute();
                root.launcherOpen = false;
                event.accepted = true;
              }
            }
          }

          Text {
            text: "close"; font.family: root.iconFont; font.pixelSize: 16
            color: root.colSubtext0; anchors.verticalCenter: parent.verticalCenter
            visible: searchInput.text !== ""
            opacity: clearMouse.containsMouse ? 0.7 : 1.0
            MouseArea { id: clearMouse; anchors.fill: parent; hoverEnabled: true; onClicked: searchInput.text = "" }
          }
        }
      }
    }
  }
}
