import QtQuick
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

  function open() {
    root.controller.show()
    if (hostWidget) hostWidget.refresh()
  }

  function close() { root.controller.hide() }
  function toggle() { opened ? close() : open() }

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

  KeyboardPanel {
    id: popup
    anchorItem: root.anchorItem
    owner: root.barIdentity
    bar: root.bar
    open: root.opened
    centerOnBar: true
    contentWidth: fittedContentWidth(Style.space(760))
    contentHeight: fittedContentHeight(content.implicitHeight)

    Flickable {
      anchors.fill: parent
      clip: true
      contentWidth: content.implicitWidth
      contentHeight: content.implicitHeight

      Column {
        id: content
        spacing: Style.space(12)

        Row {
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
