import QtQuick
import qs.Commons
import "SpotifyModel.js" as SpotifyModel

Item {
  id: root

  property QtObject bar: null
  property real position: 0          // Current position in seconds
  property real duration: 0          // Total length in seconds
  property bool isPlaying: false
  property color accentColor: "#1DB954"
  property color trackColor: bar ? Style.selectedFillFor(bar.foreground, Color.accent) : Qt.rgba(1, 1, 1, 0.15)
  property color fillColor: accentColor
  property color textColor: bar ? bar.foreground : Color.foreground

  property bool dragging: false
  property real liveSeekPosition: 0

  signal seekRequested(real targetSeconds)

  implicitWidth: Style.space(260)
  implicitHeight: Style.space(26)

  readonly property real displayPos: dragging ? liveSeekPosition : Math.max(0, Math.min(position, duration))
  readonly property real progress: duration > 0 ? Math.max(0, Math.min(1.0, displayPos / duration)) : 0
  readonly property bool _hot: trackMouseArea.containsMouse || root.dragging

  Row {
    id: rowLayout
    anchors.fill: parent
    spacing: Style.space(8)

    // Current Time Label (e.g., 1:50)
    Text {
      id: currentTimeText
      anchors.verticalCenter: parent.verticalCenter
      textFormat: Text.PlainText
      text: SpotifyModel.formatTime(root.displayPos)
      color: root.dragging ? root.accentColor : Qt.rgba(root.textColor.r, root.textColor.g, root.textColor.b, 0.75)
      font.family: root.bar ? root.bar.fontFamily : Style.font.family
      font.pixelSize: Style.font.caption
      font.weight: root.dragging ? Font.DemiBold : Font.Normal
      width: Style.space(36)
      horizontalAlignment: Text.AlignRight

      Behavior on color {
        ColorAnimation { duration: 120 }
      }
    }

    // Progress Bar Track
    Item {
      id: trackContainer
      anchors.verticalCenter: parent.verticalCenter
      width: parent.width - currentTimeText.width - totalTimeText.width - Style.space(16)
      height: Style.space(16)

      // Background groove
      Rectangle {
        id: trackBg
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.right: parent.right
        height: root._hot ? Style.space(6) : Style.space(4)
        radius: height / 2
        color: root.trackColor

        Behavior on height {
          NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
        }
      }

      // Progress Fill
      Rectangle {
        id: trackFill
        anchors.verticalCenter: trackBg.verticalCenter
        anchors.left: trackBg.left
        height: trackBg.height
        radius: trackBg.radius
        color: root._hot ? root.accentColor : root.fillColor
        width: Math.max(0, Math.min(trackBg.width, trackBg.width * root.progress))

        Behavior on width {
          enabled: !root.dragging
          NumberAnimation { duration: 100; easing.type: Easing.Linear }
        }

        Behavior on color {
          ColorAnimation { duration: 140 }
        }
      }

      // Seeking / Knob Indicator
      Rectangle {
        id: knob
        width: root.dragging ? Style.space(14) : (root._hot ? Style.space(12) : 0)
        height: width
        radius: width / 2
        color: root.bar ? root.bar.foreground : "#FFFFFF"
        anchors.verticalCenter: trackBg.verticalCenter
        x: Math.max(0, Math.min(trackBg.width - width, trackBg.width * root.progress - width / 2))
        opacity: root._hot ? 1.0 : 0.0
        scale: root.dragging ? 1.2 : 1.0

        Behavior on x {
          enabled: !root.dragging
          NumberAnimation { duration: 100; easing.type: Easing.Linear }
        }

        Behavior on width {
          NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
        }

        Behavior on opacity {
          NumberAnimation { duration: 120 }
        }

        Behavior on scale {
          NumberAnimation { duration: 120; easing.type: Easing.OutBack }
        }
      }

      // Mouse interactive area for seeking
      MouseArea {
        id: trackMouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton

        function calculatePosition(mouseX) {
          var clampedX = Math.max(0, Math.min(trackBg.width, mouseX))
          var ratio = trackBg.width > 0 ? (clampedX / trackBg.width) : 0
          return ratio * root.duration
        }

        onPressed: function(mouse) {
          root.dragging = true
          root.liveSeekPosition = calculatePosition(mouse.x)
        }

        onPositionChanged: function(mouse) {
          if (root.dragging) {
            root.liveSeekPosition = calculatePosition(mouse.x)
          }
        }

        onReleased: function(mouse) {
          if (root.dragging) {
            var target = calculatePosition(mouse.x)
            root.dragging = false
            root.seekRequested(target)
          }
        }

        onWheel: function(wheel) {
          var delta = wheel.angleDelta.y > 0 ? 5 : -5 // 5 seconds jump
          var target = Math.max(0, Math.min(root.duration, root.displayPos + delta))
          root.seekRequested(target)
        }
      }
    }

    // Total Duration Label (e.g., 5:25)
    Text {
      id: totalTimeText
      anchors.verticalCenter: parent.verticalCenter
      textFormat: Text.PlainText
      text: SpotifyModel.formatTime(root.duration)
      color: Qt.rgba(root.textColor.r, root.textColor.g, root.textColor.b, 0.6)
      font.family: root.bar ? root.bar.fontFamily : Style.font.family
      font.pixelSize: Style.font.caption
      width: Style.space(36)
      horizontalAlignment: Text.AlignLeft
    }
  }
}
