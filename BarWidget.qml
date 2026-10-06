import QtQuick
import Quickshell.Io
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "io.github.nikshay1.contributions"

  property var calendar: ({ days: [], total: 0 })
  property string error: ""
  readonly property string username: String(setting("username", "Nikshay1")).trim()
  readonly property var dayMap: {
    var result = {}
    for (var i = 0; i < calendar.days.length; i++)
      result[calendar.days[i].date] = calendar.days[i]
    return result
  }
  readonly property var recentDays: calendar.days.slice(-7)
  readonly property bool opened: panelLoader.item ? panelLoader.item.opened === true : false
  readonly property bool popoutSwitchClosing: panelLoader.item ? panelLoader.item.popoutSwitchClosing === true : false

  function colorForLevel(level) {
    return ["#161b22", "#0e4429", "#006d32", "#26a641", "#39d353"][Math.max(0, Math.min(4, level || 0))]
  }

  function refresh() {
    if (!fetch.running) fetch.running = true
  }

  function open() {
    if (panelLoader.item) panelLoader.item.open()
  }

  function close() {
    if (panelLoader.item) panelLoader.item.close()
  }

  function togglePanel() {
    if (panelLoader.item) panelLoader.item.toggle()
  }

  function closeForPopoutSwitch() {
    if (panelLoader.item) panelLoader.item.closeForPopoutSwitch()
  }

  function injectPanel() {
    var target = panelLoader.item
    if (!target) return
    target.bar = root.bar
    target.settings = root.settings
    target.anchorItem = button
    target.hostWidget = root
    target.calendar = root.calendar
    target.error = root.error
  }

  onBarChanged: injectPanel()
  onSettingsChanged: {
    injectPanel()
    refresh()
  }
  onCalendarChanged: injectPanel()
  onErrorChanged: injectPanel()
  onUsernameChanged: refresh()

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  Timer {
    interval: 30 * 60 * 1000
    running: true
    repeat: true
    onTriggered: root.refresh()
  }

  Component.onCompleted: refresh()

  Process {
    id: fetch
    command: ["python3", Qt.resolvedUrl("fetch.py").toString().replace("file://", ""), root.username]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        try {
          var result = JSON.parse(String(text || ""))
          if (result.error) {
            root.error = result.error
          } else if (result.days && result.days.length > 350) {
            root.calendar = result
            root.error = ""
          }
        } catch (e) {
          root.error = "Could not read GitHub contributions"
        }
      }
    }
  }

  Loader {
    id: panelLoader
    active: true
    source: Qt.resolvedUrl("Panel.qml")
    visible: false
    onLoaded: root.injectPanel()
  }

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    labelVisible: false
    hasVisualContent: true
    fixedWidth: root.vertical ? root.barSize : 93
    tooltipText: root.calendar.days.length
      ? root.calendar.total + " contributions in the last year · @" + root.username
      : (root.error || "Loading GitHub contributions")
    onPressed: function(b) {
      if (b === Qt.MiddleButton) root.refresh()
      else root.togglePanel()
    }

    Row {
      visible: !root.vertical
      anchors.centerIn: parent
      spacing: 3
      Text {
        text: "󰊤"
        color: root.bar ? root.bar.foreground : Color.foreground
        font.family: root.bar ? root.bar.fontFamily : Style.font.family
        font.pixelSize: 14
        anchors.verticalCenter: parent.verticalCenter
      }
      Repeater {
        model: 7
        Rectangle {
          required property int index
          width: 6
          height: 10
          radius: 1.5
          color: root.colorForLevel(root.recentDays[index] ? root.recentDays[index].level : 0)
          anchors.verticalCenter: parent.verticalCenter
        }
      }
    }

    Text {
      visible: root.vertical
      anchors.centerIn: parent
      text: "󰊤"
      color: root.bar ? root.bar.foreground : Color.foreground
      font.family: root.bar ? root.bar.fontFamily : Style.font.family
      font.pixelSize: 15
    }
  }
}
