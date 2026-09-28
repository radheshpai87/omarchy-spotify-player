import QtQuick
import qs.Commons
import "SpotifyModel.js" as SpotifyModel

Item {
  id: root

  property QtObject bar: null
  property real volumeLevel: 1.0      // 0.0 to 1.0
  property color accentColor: "#1DB954"
  property color trackColor: bar ? Style.selectedFillFor(bar.foreground, Color.accent) : Qt.rgba(1, 1, 1, 0.15)
  property color fillColor: bar ? bar.foreground : Color.foreground
  property color textColor: bar ? bar.foreground : Color.foreground

  property real prevVolume: 0.8
  property bool dragging: false
  property real liveVolume: volumeLevel

  signal adjustVolume(real target)

  onVolumeLevelChanged: if (!dragging) liveVolume = volumeLevel

  implicitWidth: Style.space(120)
  implicitHeight: Style.space(24)

  readonly property string volumeIcon: {
    var v = root.dragging ? root.liveVolume : root.volumeLevel
    if (v <= 0.001) return "󰝟"
    if (v < 0.33) return "󰕿"
    if (v < 0.66) return "󰖀"
    return "󰕾"
  }

  readonly property bool _hot: sliderMouseArea.containsMouse || root.dragging || iconMouseArea.containsMouse

  Row {
    anchors.fill: parent
    spacing: Style.space(6)

    // Volume Icon / Mute Button
    Item {
      id: iconBtn
      width: Style.space(20)
      height: Style.space(20)
      anchors.verticalCenter: parent.verticalCenter

      Text {
        anchors.centerIn: parent
        textFormat: Text.PlainText
        text: root.volumeIcon
        color: iconMouseArea.containsMouse ? root.accentColor : root.textColor
        font.family: root.bar ? root.bar.fontFamily : Style.font.family
        font.pixelSize: Style.font.body

        Behavior on color {
          ColorAnimation { duration: 120 }
        }
      }

      MouseArea {
        id: iconMouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
          if (root.volumeLevel > 0.001) {
            root.prevVolume = root.volumeLevel
            root.adjustVolume(0.0)
          } else {
            root.adjustVolume(root.prevVolume > 0.05 ? root.prevVolume : 0.8)
          }
        }
      }
    }

    // Volume Slider Track
    Item {
      id: sliderContainer
      anchors.verticalCenter: parent.verticalCenter
      width: parent.width - iconBtn.width - Style.space(6)
      height: Style.space(16)

      Rectangle {
        id: trackBg
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.right: parent.right
        height: root._hot ? Style.space(5) : Style.space(3.5)
        radius: height / 2
        color: root.trackColor

        Behavior on height {
          NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
        }
      }

      Rectangle {
        id: trackFill
        anchors.verticalCenter: trackBg.verticalCenter
        anchors.left: trackBg.left
        height: trackBg.height
        radius: trackBg.radius
        color: root._hot ? root.accentColor : root.fillColor
        width: Math.max(0, Math.min(trackBg.width, trackBg.width * (root.dragging ? root.liveVolume : root.volumeLevel)))

        Behavior on width {
          enabled: !root.dragging
          NumberAnimation { duration: 80; easing.type: Easing.OutQuad }
        }

        Behavior on color {
          ColorAnimation { duration: 120 }
        }
      }

      Rectangle {
        id: knob
        width: root.dragging ? Style.space(12) : (root._hot ? Style.space(10) : 0)
        height: width
        radius: width / 2
        color: root.bar ? root.bar.foreground : "#FFFFFF"
        anchors.verticalCenter: trackBg.verticalCenter
        x: Math.max(0, Math.min(trackBg.width - width, trackBg.width * (root.dragging ? root.liveVolume : root.volumeLevel) - width / 2))
        opacity: root._hot ? 1.0 : 0.0
        scale: root.dragging ? 1.2 : 1.0

        Behavior on x {
          enabled: !root.dragging
          NumberAnimation { duration: 80; easing.type: Easing.OutQuad }
        }

        Behavior on opacity {
          NumberAnimation { duration: 120 }
        }
      }

      MouseArea {
        id: sliderMouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton

        function calculateVolume(mouseX) {
          var clampedX = Math.max(0, Math.min(trackBg.width, mouseX))
          return trackBg.width > 0 ? (clampedX / trackBg.width) : 0
        }

        onPressed: function(mouse) {
          root.dragging = true
          root.liveVolume = calculateVolume(mouse.x)
          root.adjustVolume(root.liveVolume)
        }

        onPositionChanged: function(mouse) {
          if (root.dragging) {
            root.liveVolume = calculateVolume(mouse.x)
            root.adjustVolume(root.liveVolume)
          }
        }

        onReleased: function(mouse) {
          if (root.dragging) {
            root.dragging = false
            root.adjustVolume(root.liveVolume)
          }
        }

        onWheel: function(wheel) {
          var delta = wheel.angleDelta.y > 0 ? 0.05 : -0.05
          var next = Math.max(0, Math.min(1.0, root.volumeLevel + delta))
          root.adjustVolume(next)
        }
      }
    }
  }
}
