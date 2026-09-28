import QtQuick
import Quickshell
import Quickshell.Services.Mpris
import qs.Commons
import qs.Ui
import "SpotifyModel.js" as SpotifyModel

BarWidget {
  id: root
  moduleName: "omarchy-spotify-player"

  readonly property var mprisPlayers: Mpris.players ? Mpris.players.values : []
  readonly property var spotifyPlayer: SpotifyModel.findSpotifyPlayer(mprisPlayers)

  readonly property color brandGreen: "#1DB954"
  readonly property bool hasMedia: spotifyPlayer !== null && (spotifyPlayer.trackTitle || spotifyPlayer.trackArtist)
  readonly property bool isPlaying: spotifyPlayer ? !!spotifyPlayer.isPlaying : false
  readonly property string title: spotifyPlayer ? (spotifyPlayer.trackTitle || "") : ""
  readonly property string artist: spotifyPlayer ? (spotifyPlayer.trackArtist || spotifyPlayer.trackArtists || "") : ""
  readonly property string album: spotifyPlayer && spotifyPlayer.trackAlbum ? spotifyPlayer.trackAlbum : ""

  readonly property string tooltipText: hasMedia
    ? (title + (artist ? " — " + artist : "") + (album ? " (" + album + ")" : ""))
    : (spotifyPlayer ? "Spotify" : "Spotify (Click to open)")

  property bool popupOpen: false
  function close() { popupOpen = false }
  function open() { popupOpen = true }
  function toggle() { popupOpen = !popupOpen }

  // Forwarded popout properties for Omarchy Bar
  readonly property bool opened: popupOpen
  readonly property real openPanelIndicatorWidth: Style.bar.iconSlot
  readonly property real openPanelIndicatorHeight: Math.max(Style.space(10), Math.round(Style.bar.iconSlot * 0.55))

  visible: true
  implicitWidth: Style.bar.iconSlot
  implicitHeight: barSize

  Item {
    id: iconCanvas
    anchors.centerIn: parent
    width: Style.bar.iconCanvas
    height: Style.bar.iconCanvas

    // Subtle green glow background when playing
    Rectangle {
      anchors.centerIn: parent
      width: parent.width + Style.space(4)
      height: parent.height + Style.space(4)
      radius: width / 2
      color: root.brandGreen
      opacity: root.isPlaying ? 0.15 : 0.0

      Behavior on opacity {
        NumberAnimation { duration: 250 }
      }
    }

    // Spotify Brand Glyph
    Text {
      id: glyph
      anchors.centerIn: parent
      textFormat: Text.PlainText
      text: "󰓇"
      color: root.isPlaying
        ? root.brandGreen
        : (root.hasMedia ? root.bar.barForeground : Qt.darker(root.bar.barForeground, 1.6))
      font.family: root.bar ? root.bar.fontFamily : Style.font.family
      font.pixelSize: Style.bar.iconFont
      scale: mouseArea.pressed ? 0.9 : (mouseArea.containsMouse ? 1.12 : 1.0)

      Behavior on color {
        ColorAnimation { duration: 180 }
      }

      Behavior on scale {
        NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
      }
    }

    // Small active playback indicator dot
    Rectangle {
      width: Style.space(4)
      height: Style.space(4)
      radius: width / 2
      color: root.brandGreen
      anchors.right: parent.right
      anchors.bottom: parent.bottom
      anchors.rightMargin: -Style.space(1)
      anchors.bottomMargin: -Style.space(1)
      visible: root.isPlaying

      SequentialAnimation on opacity {
        running: root.isPlaying
        loops: Animation.Infinite
        NumberAnimation { from: 1.0; to: 0.35; duration: 900; easing.type: Easing.InOutQuad }
        NumberAnimation { from: 0.35; to: 1.0; duration: 900; easing.type: Easing.InOutQuad }
      }
    }
  }

  // ==========================================
  // BAR INTERACTION / MOUSE ACTIONS
  // ==========================================
  MouseArea {
    id: mouseArea
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

    onClicked: function(mouse) {
      if (mouse.button === Qt.LeftButton) {
        root.popupOpen = !root.popupOpen
      } else if (mouse.button === Qt.MiddleButton) {
        SpotifyModel.togglePlayPause(root.spotifyPlayer, Util)
      } else if (mouse.button === Qt.RightButton) {
        SpotifyModel.nextTrack(root.spotifyPlayer, Util)
      }
    }

    onWheel: function(wheel) {
      if (wheel.angleDelta.y > 0) {
        SpotifyModel.previousTrack(root.spotifyPlayer, Util)
      } else if (wheel.angleDelta.y < 0) {
        SpotifyModel.nextTrack(root.spotifyPlayer, Util)
      }
    }

    onEntered: {
      if (root.bar) {
        root.bar.showTooltip(root, root.tooltipText)
      }
    }

    onExited: {
      if (root.bar) {
        root.bar.hideTooltip(root)
      }
    }
  }

  // ==========================================
  // RICH SPOTIFY POPUP CARD
  // ==========================================
  SpotifyPopup {
    id: popup
    anchorItem: root
    bar: root.bar
    owner: root
    open: root.popupOpen
    player: root.spotifyPlayer
  }

  Timer {
    id: popupTicker
    interval: 1000
    running: root.popupOpen && root.isPlaying
    repeat: true
    onTriggered: popup.tickPosition()
  }
}
