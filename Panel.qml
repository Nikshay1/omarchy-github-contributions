import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Commons
import qs.Ui

Panel {
  id: root
  moduleName: "io.github.nikshay1.contributions"
  manageIpc: false

  property var anchorItem: null
  property var hostWidget: null
  property var calendar: ({ days: [], total: 0 })
  property string error: ""
  property int hoveredIndex: -1
  readonly property var barIdentity: hostWidget || root
  readonly property int cell: 10
  readonly property int gap: 3
  readonly property int weekCount: Math.ceil((calendar.days.length + firstWeekday) / 7)
  readonly property int firstWeekday: calendar.days.length
    ? new Date(calendar.days[0].date + "T12:00:00").getDay() : 0
  readonly property color foreground: bar ? bar.foreground : Color.foreground
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family
  property real positionX: Number(setting("popupX", -1))
  property real positionY: Number(setting("popupY", -1))

  function open() {
    if (bar) bar.requestPopout(barIdentity)
    root.controller.show()
    if (hostWidget) hostWidget.refresh()
  }

  function close() {
    root.controller.hide()
    if (bar) bar.releasePopout(barIdentity)
  }
  function toggle() { opened ? close() : open() }

  function savePosition() {
    var entry = { id: moduleName }
    for (var key in settings) if (key !== "id") entry[key] = settings[key]
    entry.popupX = Math.round(positionX)
    entry.popupY = Math.round(positionY)
    settings = entry
    if (hostWidget) hostWidget.settings = entry
    if (bar && bar.shell && typeof bar.shell.updateEntryInline === "function")
      bar.shell.updateEntryInline(moduleName, entry)
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
    screen: root.anchorItem && root.anchorItem.QsWindow.window
      ? root.anchorItem.QsWindow.window.screen : null
    visible: root.opened
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    anchors { top: true; bottom: true; left: true; right: true }
    WlrLayershell.namespace: "omarchy-github-contributions"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    mask: Region { item: card }

    BorderSurface {
      id: card
      width: Math.min(Style.space(760), popup.width - Style.gapsOut * 2)
      height: Math.min(content.implicitHeight + contentTopInset + contentBottomInset,
                       popup.height - Style.gapsOut * 2)
      x: root.positionX >= 0 ? Math.max(0, Math.min(root.positionX, popup.width - width))
        : Math.round((popup.width - width) / 2)
      y: root.positionY >= 0 ? Math.max(0, Math.min(root.positionY, popup.height - height))
        : (root.bar && root.bar.position === "bottom"
          ? popup.height - height - root.bar.barSize - Style.gapsOut
          : root.bar ? root.bar.barSize + Style.gapsOut : Style.gapsOut)
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
              text: "@" + String(root.setting("username", "Nikshay1"))
              color: root.foreground
              opacity: 0.6
              font.family: root.fontFamily
              font.pixelSize: 12
              anchors.verticalCenter: parent.verticalCenter
            }
          }

          MouseArea {
            anchors.fill: parent
            anchors.rightMargin: Style.space(28)
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

          Text {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            text: "×"
            color: root.foreground
            font.family: root.fontFamily
            font.pixelSize: 18
            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: root.close()
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
              color: root.hostWidget ? root.hostWidget.colorForLevel(day ? day.level : 0) : "#161b22"
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
              color: root.hostWidget ? root.hostWidget.colorForLevel(index) : "#161b22"
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
