import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.Commons
import qs.Ui

Item {
  id: root
  property var shell: null
  property var calendar: ({ days: [], total: 0 })
  property string error: ""
  property int hoveredIndex: -1
  property string username: "Nikshay1"
  property real positionX: -1
  property real positionY: -1
  readonly property int cell: 10
  readonly property int gap: 3
  readonly property int weekCount: Math.ceil((calendar.days.length + firstWeekday) / 7)
  readonly property int firstWeekday: calendar.days.length
    ? new Date(calendar.days[0].date + "T12:00:00").getDay() : 0
  readonly property color foreground: Color.foreground
  readonly property string fontFamily: Style.font.family

  function colorForLevel(level) {
    return ["#161b22", "#0e4429", "#006d32", "#26a641", "#39d353"][Math.max(0, Math.min(4, level || 0))]
  }

  function refresh() {
    if (!fetch.running) fetch.running = true
  }

  function applyState(raw) {
    try {
      var state = JSON.parse(raw)
      if (typeof state.username === "string" && state.username.trim())
        username = state.username.trim()
      if (state.x !== undefined && isFinite(Number(state.x)) && Number(state.x) >= 0)
        positionX = Number(state.x)
      if (state.y !== undefined && isFinite(Number(state.y)) && Number(state.y) >= 0)
        positionY = Number(state.y)
    } catch (e) { /* No saved position yet. */ }
  }

  function savePosition() {
    stateFile.setText(JSON.stringify({
      username: username,
      x: Math.round(positionX),
      y: Math.round(positionY)
    }, null, 2) + "\n")
  }

  onUsernameChanged: refresh()
  Component.onCompleted: refresh()

  Timer {
    interval: 30 * 60 * 1000
    running: true
    repeat: true
    onTriggered: root.refresh()
  }

  FileView {
    id: stateFile
    path: Quickshell.env("HOME") + "/.local/state/omarchy/github-contributions.json"
    watchChanges: true
    atomicWrites: true
    printErrors: false
    onLoaded: root.applyState(text())
    onFileChanged: reload()
  }

  Process {
    id: fetch
    command: ["python3", Qt.resolvedUrl("fetch.py").toString().replace("file://", ""), root.username]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        try {
          var result = JSON.parse(String(text || ""))
          if (result.error) root.error = result.error
          else if (result.days && result.days.length > 350) {
            if (result.username !== root.username) { root.refresh(); return }
            root.calendar = result
            root.error = ""
          }
        } catch (e) {
          root.error = "Could not read GitHub contributions"
        }
      }
    }
  }

  function dateAt(index) {
    return calendar.days[index - firstWeekday]
  }

  function dateLabel(day) {
    if (!day) return ""
    var date = new Date(day.date + "T12:00:00")
    return day.count + (day.count === 1 ? " contribution" : " contributions")
      + " on " + Qt.formatDate(date, "MMMM d, yyyy")
  }

  function monthAt(week) {
    var day = dateAt(week * 7)
    if (!day) return ""
    var date = new Date(day.date + "T12:00:00")
    if (week !== 0) {
      var previous = dateAt((week - 1) * 7)
      if (previous && previous.date.slice(0, 7) === day.date.slice(0, 7)) return ""
    }
    return Qt.formatDate(date, "MMM")
  }

  PanelWindow {
    id: popup
    screen: Quickshell.screens.length ? Quickshell.screens[0] : null
    visible: true
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    anchors { top: true; bottom: true; left: true; right: true }
    WlrLayershell.namespace: "omarchy-github-contributions"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    mask: Region { item: card }

    BorderSurface {
      id: card
      width: Math.max(120, Math.min(Style.space(760), popup.width - Style.gapsOut * 2))
      height: Math.max(80, Math.min(content.implicitHeight + contentTopInset + contentBottomInset,
                                   popup.height - Style.gapsOut * 2))
      x: root.positionX >= 0 ? Math.max(0, Math.min(root.positionX, popup.width - width))
        : Math.round((popup.width - width) / 2)
      y: root.positionY >= 0 ? Math.max(0, Math.min(root.positionY, popup.height - height))
        : Style.space(40)
      color: Color.popups.background
      borderSpec: Border.surfaceSpec("popups", "border", Color.popups.border, Math.max(1, Style.space(2)))
      padding: Style.spacing.popupPadding
      radius: Style.cornerRadius

      Flickable {
        anchors.fill: parent
        anchors.topMargin: card.contentTopInset
        anchors.rightMargin: card.contentRightInset
        anchors.bottomMargin: card.contentBottomInset
        anchors.leftMargin: card.contentLeftInset
        clip: true
        contentWidth: content.implicitWidth
        contentHeight: content.implicitHeight
        interactive: contentWidth > width || contentHeight > height

      Column {
        id: content
        spacing: Style.space(12)

        Item {
          width: card.width - card.contentLeftInset - card.contentRightInset
          height: heading.implicitHeight

          Row {
            id: heading
            spacing: Style.space(8)
            Text {
              text: calendar.days.length ? calendar.total + " contributions in the last year" : "GitHub contributions"
              color: root.foreground
              font.family: root.fontFamily
              font.pixelSize: 17
              font.bold: true
            }
            Text {
              text: "@" + root.username
              color: root.foreground
              opacity: 0.6
              font.family: root.fontFamily
              font.pixelSize: 12
              anchors.verticalCenter: parent.verticalCenter
            }
          }

          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.OpenHandCursor
            property real startX: 0
            property real startY: 0
            property real startPointerX: 0
            property real startPointerY: 0
            onPressed: function(mouse) {
              var point = mapToItem(null, mouse.x, mouse.y)
              startPointerX = point.x
              startPointerY = point.y
              startX = card.x
              startY = card.y
              cursorShape = Qt.ClosedHandCursor
            }
            onPositionChanged: function(mouse) {
              if (!(mouse.buttons & Qt.LeftButton)) return
              var point = mapToItem(null, mouse.x, mouse.y)
              root.positionX = Math.max(0, Math.min(startX + point.x - startPointerX, popup.width - card.width))
              root.positionY = Math.max(0, Math.min(startY + point.y - startPointerY, popup.height - card.height))
            }
            onReleased: {
              cursorShape = Qt.OpenHandCursor
              root.savePosition()
            }
          }

        }

        Text {
          visible: !calendar.days.length || error !== ""
          text: error || "Loading contribution calendar…"
          color: root.foreground
          opacity: 0.75
          font.family: root.fontFamily
          font.pixelSize: 12
        }

        Item {
          visible: calendar.days.length > 0
          width: Style.space(34) + root.weekCount * (root.cell + root.gap)
          height: Style.space(23) + 7 * (root.cell + root.gap)

          Repeater {
            model: root.weekCount
            Text {
              required property int index
              x: Style.space(34) + index * (root.cell + root.gap)
              y: 0
              text: root.monthAt(index)
              color: root.foreground
              opacity: 0.7
              font.family: root.fontFamily
              font.pixelSize: 10
            }
          }

          Repeater {
            model: ["", "Mon", "", "Wed", "", "Fri", ""]
            Text {
              required property int index
              required property string modelData
              x: 0
              y: Style.space(22) + index * (root.cell + root.gap) - 1
              text: modelData
              color: root.foreground
              opacity: 0.65
              font.family: root.fontFamily
              font.pixelSize: 10
            }
          }

          Repeater {
            model: root.weekCount * 7
            Rectangle {
              required property int index
              readonly property var day: root.dateAt(index)
              x: Style.space(34) + Math.floor(index / 7) * (root.cell + root.gap)
              y: Style.space(22) + (index % 7) * (root.cell + root.gap)
              width: root.cell
              height: root.cell
              radius: 2
              visible: !!day
              color: root.colorForLevel(day ? day.level : 0)
              border.width: root.hoveredIndex === index ? 1 : 0
              border.color: root.foreground

              MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                onEntered: root.hoveredIndex = index
                onExited: if (root.hoveredIndex === index) root.hoveredIndex = -1
              }
            }
          }
        }

        Row {
          spacing: Style.space(6)
          Text {
            width: Style.space(430)
            text: root.hoveredIndex >= 0 ? root.dateLabel(root.dateAt(root.hoveredIndex)) : "Hover a square for its daily count"
            color: root.foreground
            opacity: 0.7
            font.family: root.fontFamily
            font.pixelSize: 11
          }
          Text {
            text: "Less"
            color: root.foreground
            opacity: 0.6
            font.family: root.fontFamily
            font.pixelSize: 11
          }
          Repeater {
            model: 5
            Rectangle {
              required property int index
              width: root.cell
              height: root.cell
              radius: 2
              color: root.colorForLevel(index)
              anchors.verticalCenter: parent.verticalCenter
            }
          }
          Text {
            text: "More"
            color: root.foreground
            opacity: 0.6
            font.family: root.fontFamily
            font.pixelSize: 11
          }
        }
      }
    }
    }
  }
}
