import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

import "fuzzysort.js" as FuzzySort

PanelWindow {
  id: clipWin

  property bool showing: false
  visible: showing
  focusable: true
  anchors { top: true; bottom: true; left: true; right: true }
  exclusiveZone: -1
  color: Qt.rgba(0, 0, 0, 0.4 * animProgress)
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

  property real animProgress: 0
  property var entries: []
  property string debouncedSearch: ""
  property int selectedIndex: 0

  Timer {
    id: searchDebounce; interval: 60
    onTriggered: clipWin.debouncedSearch = clipSearch.text
  }

  readonly property var preparedEntries: entries.map(e => ({
    name: FuzzySort.prepare(e.replace(/^\s*\S+\s+/, "")),
    entry: e
  }))

  readonly property var filteredEntries: {
    let q = debouncedSearch.trim();
    if (q === "") return entries.slice(0, 200);
    return FuzzySort.go(q, preparedEntries, { all: true, key: "name" })
      .slice(0, 200)
      .map(r => r.obj.entry);
  }

  onFilteredEntriesChanged: {
    if (selectedIndex >= filteredEntries.length)
      selectedIndex = Math.max(0, filteredEntries.length - 1);
  }

  function entryIsImage(entry) {
    return /^\d+\t\[\[.*binary data.*\d+x\d+.*\]\]$/.test(entry);
  }

  function entryText(entry) {
    return entry.replace(/^\d+\t/, "");
  }

  function shellEscape(str) {
    return str.replace(/'/g, "'\\''");
  }

  function copyEntry(entry) {
    Quickshell.execDetached(["bash", "-c",
      "printf '" + shellEscape(entry) + "' | cliphist decode | wl-copy"]);
    root.clipboardOpen = false;
  }

  function deleteEntry(entry) {
    delProc.entry = entry;
    delProc.running = true;
    delProc.entry = "";
  }

  function refresh() {
    readProc.buffer = [];
    readProc.running = true;
  }

  Component.onCompleted: {
    Quickshell.execDetached(["bash", "-c", "rm -rf /tmp/qs-clipboard; mkdir -p /tmp/qs-clipboard"]);
  }

  Process {
    id: readProc
    property var buffer: []
    command: ["cliphist", "list"]
    stdout: SplitParser { onRead: line => readProc.buffer.push(line) }
    onExited: (code) => { if (code === 0) clipWin.entries = readProc.buffer; }
  }

  Process {
    id: delProc
    property string entry: ""
    command: ["bash", "-c", "printf '" + clipWin.shellEscape(delProc.entry) + "' | cliphist delete"]
    onExited: clipWin.refresh()
  }

  Connections {
    target: Quickshell
    function onClipboardTextChanged() { refreshDebounce.restart() }
  }
  Timer { id: refreshDebounce; interval: 50; onTriggered: clipWin.refresh() }

  Connections {
    target: root
    function onClipboardOpenChanged() {
      if (root.clipboardOpen) {
        clipWin.refresh();
        showing = true;
        animProgress = 0;
        openAnim.start();
        clipSearch.text = "";
        debouncedSearch = "";
        selectedIndex = 0;
        clipSearch.forceActiveFocus();
      } else {
        openAnim.stop();
        closeAnim.start();
      }
    }
  }

  NumberAnimation {
    id: openAnim; target: clipWin; property: "animProgress"
    from: 0; to: 1; duration: 200; easing.type: Easing.OutCubic
  }
  NumberAnimation {
    id: closeAnim; target: clipWin; property: "animProgress"
    from: clipWin.animProgress; to: 0; duration: 150; easing.type: Easing.InCubic
    onFinished: clipWin.showing = false
  }

  HyprlandFocusGrab {
    active: root.clipboardOpen
    windows: [clipWin]
    onCleared: root.clipboardOpen = false
  }

  MouseArea {
    anchors.fill: parent
    onClicked: root.clipboardOpen = false
  }

  Rectangle {
    id: card
    anchors.centerIn: parent
    width: 550
    height: Math.min(parent.height * 0.7, 650)
    radius: 16
    color: Qt.rgba(root.colBg.r, root.colBg.g, root.colBg.b, 0.95)
    border.width: 1
    border.color: Qt.rgba(root.colText.r, root.colText.g, root.colText.b, 0.08)
    clip: true

    opacity: clipWin.animProgress
    transform: Scale {
      origin.x: card.width / 2; origin.y: card.height / 2
      xScale: 0.96 + 0.04 * clipWin.animProgress
      yScale: 0.96 + 0.04 * clipWin.animProgress
    }

    MouseArea { anchors.fill: parent }

    Column {
      id: cardContent
      anchors.fill: parent
      anchors.margins: 12
      spacing: 8

      Rectangle {
        width: parent.width; height: 40; radius: 20
        color: Qt.rgba(root.colSurface0.r, root.colSurface0.g, root.colSurface0.b, 0.6)

        Row {
          anchors.fill: parent; anchors.leftMargin: 14; anchors.rightMargin: 14; spacing: 8

          Text {
            text: "content_paste_search"
            font.family: root.iconFont; font.pixelSize: 18
            color: root.colSubtext0; anchors.verticalCenter: parent.verticalCenter
          }

          TextInput {
            id: clipSearch
            width: parent.width - 80
            anchors.verticalCenter: parent.verticalCenter
            font.family: root.textFont; font.pixelSize: 13
            color: root.colText; selectionColor: root.colAccent; clip: true

            onTextChanged: { clipWin.selectedIndex = 0; searchDebounce.restart(); }

            Text {
              anchors.fill: parent; verticalAlignment: Text.AlignVCenter
              text: "search clipboard..."
              font.family: root.textFont; font.pixelSize: 13; color: root.colSurface1
              visible: clipSearch.text === ""
            }

            Keys.onPressed: event => {
              if (event.key === Qt.Key_Escape) {
                root.clipboardOpen = false; event.accepted = true;
              } else if (event.key === Qt.Key_Up) {
                clipWin.selectedIndex = Math.max(clipWin.selectedIndex - 1, 0);
                clipList.positionViewAtIndex(clipWin.selectedIndex, ListView.Contain);
                event.accepted = true;
              } else if (event.key === Qt.Key_Down) {
                clipWin.selectedIndex = Math.min(clipWin.selectedIndex + 1, clipList.count - 1);
                clipList.positionViewAtIndex(clipWin.selectedIndex, ListView.Contain);
                event.accepted = true;
              } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                let items = clipWin.filteredEntries;
                if (items.length > 0 && clipWin.selectedIndex < items.length)
                  clipWin.copyEntry(items[clipWin.selectedIndex]);
                event.accepted = true;
              } else if (event.key === Qt.Key_Delete) {
                let items = clipWin.filteredEntries;
                if (items.length > 0 && clipWin.selectedIndex < items.length)
                  clipWin.deleteEntry(items[clipWin.selectedIndex]);
                event.accepted = true;
              }
            }
          }

          Text {
            text: clipWin.filteredEntries.length + ""
            font.family: root.textFont; font.pixelSize: 10
            color: root.colSubtext0; anchors.verticalCenter: parent.verticalCenter
            visible: clipWin.entries.length > 0
          }
        }
      }

      Text {
        visible: clipWin.entries.length === 0
        text: "clipboard is empty"
        font.family: root.textFont; font.pixelSize: 12; color: root.colSubtext0
        anchors.horizontalCenter: parent.horizontalCenter
        topPadding: 40
      }

      Text {
        visible: clipWin.entries.length > 0 && clipWin.filteredEntries.length === 0
        text: "no matches"
        font.family: root.textFont; font.pixelSize: 12; color: root.colSubtext0
        anchors.horizontalCenter: parent.horizontalCenter
        topPadding: 40
      }

      ListView {
        id: clipList
        width: parent.width
        height: card.height - 72
        model: clipWin.filteredEntries
        clip: true
        currentIndex: clipWin.selectedIndex
        spacing: 2

        highlightFollowsCurrentItem: false
        highlight: Rectangle {
          radius: 10
          color: Qt.rgba(root.colAccent.r, root.colAccent.g, root.colAccent.b, 0.1)
          y: clipList.currentItem ? clipList.currentItem.y : 0
          width: clipList.width
          height: clipList.currentItem ? clipList.currentItem.height : 0
          Behavior on y { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
        }

        delegate: Item {
          id: entryDel
          required property var modelData
          required property int index

          property bool isImage: clipWin.entryIsImage(modelData)
          property string entryNum: {
            let m = modelData.match(/^(\d+)\t/);
            return m ? m[1] : "0";
          }
          property int imgW: {
            if (!isImage) return 0;
            let m = modelData.match(/(\d+)x(\d+)/);
            return m ? parseInt(m[1]) : 100;
          }
          property int imgH: {
            if (!isImage) return 0;
            let m = modelData.match(/(\d+)x(\d+)/);
            return m ? parseInt(m[2]) : 100;
          }
          property string imgPath: "/tmp/qs-clipboard/" + entryNum
          property real imgScale: Math.min(
            (clipList.width - 60) / Math.max(imgW, 1),
            120 / Math.max(imgH, 1), 1
          )
          property bool imgReady: false

          width: clipList.width
          height: isImage ? Math.max(imgH * imgScale + 24, 50) : 44

          Component.onCompleted: { if (isImage) decodeProc.running = true }

          Process {
            id: decodeProc
            command: ["bash", "-c",
              "[ -f \"$1\" ] || printf '%s' \"$2\" | cliphist decode > \"$1\"",
              "_", entryDel.imgPath, entryDel.modelData]
            onExited: (code) => { if (code === 0) entryDel.imgReady = true }
          }

          Rectangle {
            anchors.fill: parent; radius: 10
            color: entryMouse.containsMouse && index !== clipWin.selectedIndex
              ? Qt.rgba(root.colSurface0.r, root.colSurface0.g, root.colSurface0.b, 0.3)
              : "transparent"
            Behavior on color { ColorAnimation { duration: 100 } }
          }

          Row {
            anchors.left: parent.left; anchors.right: parent.right
            anchors.leftMargin: 10; anchors.rightMargin: 30
            anchors.verticalCenter: parent.verticalCenter
            spacing: 10

            Text {
              text: entryDel.isImage ? "image" : "content_paste"
              font.family: root.iconFont; font.pixelSize: 16
              color: root.colSubtext0
              anchors.verticalCenter: parent.verticalCenter
            }

            Text {
              visible: !entryDel.isImage
              text: clipWin.entryText(entryDel.modelData)
              font.family: root.textFont; font.pixelSize: 12; color: root.colText
              elide: Text.ElideRight; width: parent.width - 40
              anchors.verticalCenter: parent.verticalCenter
              maximumLineCount: 1
            }

            Column {
              visible: entryDel.isImage
              anchors.verticalCenter: parent.verticalCenter
              spacing: 4

              Rectangle {
                width: entryDel.imgW * entryDel.imgScale
                height: entryDel.imgH * entryDel.imgScale
                radius: 6; color: root.colSurface0; clip: true

                Image {
                  anchors.fill: parent
                  source: entryDel.imgReady ? "file://" + entryDel.imgPath : ""
                  fillMode: Image.PreserveAspectFit
                  asynchronous: true
                  sourceSize.width: parent.width
                  sourceSize.height: parent.height
                }
              }

              Text {
                text: entryDel.imgW + " x " + entryDel.imgH
                font.family: root.textFont; font.pixelSize: 9; color: root.colSubtext0
              }
            }
          }

          Text {
            anchors.right: parent.right; anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            text: "close"; font.family: root.iconFont; font.pixelSize: 14
            color: delMouse.containsMouse ? root.colRed : root.colSubtext0
            visible: entryMouse.containsMouse || index === clipWin.selectedIndex
            Behavior on color { ColorAnimation { duration: 100 } }

            MouseArea {
              id: delMouse; anchors.fill: parent; hoverEnabled: true
              anchors.margins: -6
              onClicked: clipWin.deleteEntry(entryDel.modelData)
            }
          }

          MouseArea {
            id: entryMouse; hoverEnabled: true; anchors.fill: parent; z: -1
            onClicked: clipWin.copyEntry(entryDel.modelData)
            onEntered: clipWin.selectedIndex = index
          }
        }
      }
    }
  }
}
