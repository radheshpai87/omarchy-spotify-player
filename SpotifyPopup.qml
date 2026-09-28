import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui
import "SpotifyModel.js" as SpotifyModel

PopupCard {
  id: root

  property var player: null
  readonly property bool isConnected: player !== null && (player.trackTitle || player.trackArtist || player.isPlaying || player.canControl)
  property color brandGreen: "#1DB954"
  property color brandGreenHover: "#1ED760"
  property color brandGreenDim: Qt.rgba(0.114, 0.725, 0.329, 0.2)
  property color brandGreenGlow: Qt.rgba(0.114, 0.725, 0.329, 0.35)

  property string trackTitle: player ? (player.trackTitle || "No Track") : "Spotify Offline"
  property string trackArtist: player ? (player.trackArtist || player.trackArtists || "Spotify") : "Spotify is not running"
  property string trackAlbum: player && player.trackAlbum ? player.trackAlbum : ""
  property string trackArtUrl: player && player.trackArtUrl ? player.trackArtUrl : ""
  property bool isPlaying: player ? !!player.isPlaying : false
  property real trackPosition: player && player.position !== undefined ? player.position : 0
  property real trackDuration: player && player.length !== undefined ? player.length : 0
  property real playerVolume: player && player.volume !== undefined ? player.volume : 1.0
  property bool isShuffle: player && player.shuffle !== undefined ? !!player.shuffle : false
  property string loopMode: player && player.loopState !== undefined ? String(player.loopState) : "None"

  property real localPosition: trackPosition
  property bool isDraggingSeek: false

  onTrackPositionChanged: {
    if (!isDraggingSeek) {
      localPosition = trackPosition
    }
  }

  contentWidth: root.fittedContentWidth(Style.space(400))
  contentHeight: root.fittedContentHeight(root.isConnected ? mainColumn.implicitHeight : offlineColumn.implicitHeight)

  function tickPosition() {
    if (root.player && root.player.position !== undefined) {
      root.localPosition = Math.min(root.trackDuration, root.player.position)
    } else {
      root.localPosition = Math.min(root.trackDuration, root.localPosition + 1)
    }
  }

  // ==========================================
  // STATE A: SPOTIFY CONNECTED / ACTIVE PLAYER
  // ==========================================
  Column {
    id: mainColumn
    anchors.fill: parent
    spacing: Style.space(14)
    visible: root.isConnected

    // 1. HERO SECTION: ALBUM ART & METADATA
    Row {
      id: heroRow
      width: parent.width
      spacing: Style.space(14)

      // Album Art with Ambient Glow Aura
      Item {
        id: artContainer
        width: Style.space(82)
        height: Style.space(82)
        anchors.verticalCenter: parent.verticalCenter

        // Ambient Glow
        Rectangle {
          anchors.centerIn: parent
          width: parent.width + Style.space(10)
          height: parent.height + Style.space(10)
          radius: Style.space(16)
          color: root.brandGreen
          opacity: root.isPlaying ? 0.28 : 0.08

          Behavior on opacity {
            NumberAnimation { duration: 300 }
          }
        }

        // Album Art Box
        BorderSurface {
          id: artSurface
          anchors.fill: parent
          radius: Style.space(12)
          color: Style.normalFillFor(root.bar.foreground, Color.accent)
          borderSpec: Border.controlSpec("normal", root.bar.foreground, Color.accent)
          clip: true

          Image {
            id: albumImage
            anchors.fill: parent
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            source: root.trackArtUrl
            visible: source !== ""

            Behavior on opacity {
              NumberAnimation { duration: 250 }
            }
          }

          // Fallback Spotify Icon if no art
          Text {
            anchors.centerIn: parent
            visible: !albumImage.visible || albumImage.status !== Image.Ready
            text: "󰓇"
            color: root.brandGreen
            font.family: root.bar ? root.bar.fontFamily : Style.font.family
            font.pixelSize: Style.font.displayLarge
          }

          // Hover Overlay to Open Spotify
          Rectangle {
            id: artHoverOverlay
            anchors.fill: parent
            color: Qt.rgba(0, 0, 0, 0.45)
            opacity: artMouseArea.containsMouse ? 1.0 : 0.0

            Behavior on opacity {
              NumberAnimation { duration: 140 }
            }

            Text {
              anchors.centerIn: parent
              textFormat: Text.PlainText
              text: "󰏌"
              color: "#FFFFFF"
              font.family: root.bar ? root.bar.fontFamily : Style.font.family
              font.pixelSize: Style.font.heading
            }
          }

          MouseArea {
            id: artMouseArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: SpotifyModel.raiseOrLaunchSpotify(root.player, Util)
          }
        }
      }

      // Metadata Column
      Column {
        id: metaColumn
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width - artContainer.width - heroRow.spacing
        spacing: Style.space(4)

        // Live Status Pill Badge
        Row {
          spacing: Style.space(6)

          Rectangle {
            width: Style.space(8)
            height: Style.space(8)
            radius: width / 2
            color: root.isPlaying ? root.brandGreen : Qt.darker(root.bar.foreground, 1.8)
            anchors.verticalCenter: parent.verticalCenter

            SequentialAnimation on opacity {
              running: root.isPlaying
              loops: Animation.Infinite
              NumberAnimation { from: 1.0; to: 0.35; duration: 900; easing.type: Easing.InOutQuad }
              NumberAnimation { from: 0.35; to: 1.0; duration: 900; easing.type: Easing.InOutQuad }
            }
          }

          Text {
            textFormat: Text.PlainText
            text: "SPOTIFY" + (root.isPlaying ? " · PLAYING" : " · PAUSED")
            color: root.isPlaying ? root.brandGreen : Qt.rgba(root.bar.foreground.r, root.bar.foreground.g, root.bar.foreground.b, 0.6)
            font.family: root.bar ? root.bar.fontFamily : Style.font.family
            font.pixelSize: Math.max(9, Style.font.caption - 1)
            font.weight: Font.Bold
            font.letterSpacing: 0.8
          }
        }

        // Song Title
        Item {
          id: titleClip
          width: parent.width
          height: titleText.implicitHeight
          clip: true

          Text {
            id: titleText
            textFormat: Text.PlainText
            text: root.trackTitle
            color: root.bar ? root.bar.foreground : Color.foreground
            font.family: root.bar ? root.bar.fontFamily : Style.font.family
            font.pixelSize: Style.font.heading
            font.weight: Font.Bold
            width: implicitWidth > parent.width ? implicitWidth : parent.width
            elide: implicitWidth > parent.width && !titleHover.containsMouse ? Text.ElideRight : Text.ElideNone

            NumberAnimation on x {
              running: titleText.implicitWidth > titleClip.width && titleHover.containsMouse
              loops: Animation.Infinite
              duration: Math.max(4000, titleText.implicitWidth * 28)
              from: 0
              to: -(titleText.implicitWidth - titleClip.width + 20)
              easing.type: Easing.InOutQuad
            }
          }

          HoverHandler { id: titleHover }
        }

        // Artist Name
        Text {
          textFormat: Text.PlainText
          text: root.trackArtist
          color: Qt.rgba(root.bar.foreground.r, root.bar.foreground.g, root.bar.foreground.b, 0.85)
          font.family: root.bar ? root.bar.fontFamily : Style.font.family
          font.pixelSize: Style.font.bodySmall
          font.weight: Font.Medium
          elide: Text.ElideRight
          width: parent.width
        }

        // Album Name
        Text {
          textFormat: Text.PlainText
          text: root.trackAlbum
          color: Qt.rgba(root.bar.foreground.r, root.bar.foreground.g, root.bar.foreground.b, 0.5)
          font.family: root.bar ? root.bar.fontFamily : Style.font.family
          font.pixelSize: Style.font.caption
          elide: Text.ElideRight
          width: parent.width
          visible: text !== ""
        }
      }
    }

    // 2. PLAYBACK CONTROLS ROW (Matching Screenshot)
    Row {
      id: controlsRow
      anchors.horizontalCenter: parent.horizontalCenter
      spacing: Style.space(14)

      // Shuffle Button
      Rectangle {
        id: shuffleBtn
        width: Style.space(36)
        height: Style.space(36)
        radius: width / 2
        anchors.verticalCenter: parent.verticalCenter
        color: root.isShuffle ? root.brandGreenDim : (shuffleMouse.containsMouse ? Style.hoverFillFor(root.bar.foreground, Color.accent) : "transparent")

        Behavior on color { ColorAnimation { duration: 120 } }

        Text {
          anchors.centerIn: parent
          textFormat: Text.PlainText
          text: "󰒟"
          color: root.isShuffle ? root.brandGreen : (shuffleMouse.containsMouse ? root.bar.foreground : Qt.rgba(root.bar.foreground.r, root.bar.foreground.g, root.bar.foreground.b, 0.6))
          font.family: root.bar ? root.bar.fontFamily : Style.font.family
          font.pixelSize: Style.font.iconLarge

          Behavior on color { ColorAnimation { duration: 120 } }
        }

        MouseArea {
          id: shuffleMouse
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: {
            root.isShuffle = SpotifyModel.toggleShuffle(root.player, root.isShuffle, Util)
          }
        }
      }

      // Previous Track Button
      Rectangle {
        id: prevBtn
        width: Style.space(40)
        height: Style.space(40)
        radius: width / 2
        anchors.verticalCenter: parent.verticalCenter
        color: prevMouse.containsMouse ? Style.hoverFillFor(root.bar.foreground, Color.accent) : "transparent"
        scale: prevMouse.pressed ? 0.92 : (prevMouse.containsMouse ? 1.08 : 1.0)

        Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }
        Behavior on color { ColorAnimation { duration: 120 } }

        Text {
          anchors.centerIn: parent
          textFormat: Text.PlainText
          text: "󰒮"
          color: prevMouse.containsMouse ? root.bar.foreground : Qt.rgba(root.bar.foreground.r, root.bar.foreground.g, root.bar.foreground.b, 0.85)
          font.family: root.bar ? root.bar.fontFamily : Style.font.family
          font.pixelSize: Style.font.heading
        }

        MouseArea {
          id: prevMouse
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: SpotifyModel.previousTrack(root.player, Util)
        }
      }

      // Play / Pause Hero Button (Vibrant & Animated)
      Rectangle {
        id: playPauseBtn
        width: Style.space(52)
        height: Style.space(52)
        radius: width / 2
        anchors.verticalCenter: parent.verticalCenter
        color: playPauseMouse.containsMouse ? root.brandGreenHover : root.brandGreen
        scale: playPauseMouse.pressed ? 0.92 : (playPauseMouse.containsMouse ? 1.08 : 1.0)

        Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutBack } }
        Behavior on color { ColorAnimation { duration: 120 } }

        // Radiant Outer Glow Pulse
        Rectangle {
          anchors.centerIn: parent
          width: parent.width + Style.space(10)
          height: parent.height + Style.space(10)
          radius: width / 2
          color: root.brandGreen
          opacity: playPauseMouse.containsMouse ? 0.4 : (root.isPlaying ? 0.2 : 0.08)
          z: -1

          Behavior on opacity { NumberAnimation { duration: 150 } }
        }

        Text {
          anchors.centerIn: parent
          anchors.horizontalCenterOffset: root.isPlaying ? 0 : Style.space(1.5)
          textFormat: Text.PlainText
          text: root.isPlaying ? "󰏤" : "󰐊"
          color: "#000000"
          font.family: root.bar ? root.bar.fontFamily : Style.font.family
          font.pixelSize: Style.font.display
          font.weight: Font.Bold
        }

        MouseArea {
          id: playPauseMouse
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: SpotifyModel.togglePlayPause(root.player, Util)
        }
      }

      // Next Track Button
      Rectangle {
        id: nextBtn
        width: Style.space(40)
        height: Style.space(40)
        radius: width / 2
        anchors.verticalCenter: parent.verticalCenter
        color: nextMouse.containsMouse ? Style.hoverFillFor(root.bar.foreground, Color.accent) : "transparent"
        scale: nextMouse.pressed ? 0.92 : (nextMouse.containsMouse ? 1.08 : 1.0)

        Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }
        Behavior on color { ColorAnimation { duration: 120 } }

        Text {
          anchors.centerIn: parent
          textFormat: Text.PlainText
          text: "󰒭"
          color: nextMouse.containsMouse ? root.bar.foreground : Qt.rgba(root.bar.foreground.r, root.bar.foreground.g, root.bar.foreground.b, 0.85)
          font.family: root.bar ? root.bar.fontFamily : Style.font.family
          font.pixelSize: Style.font.heading
        }

        MouseArea {
          id: nextMouse
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: SpotifyModel.nextTrack(root.player, Util)
        }
      }

      // Repeat / Loop Button
      Rectangle {
        id: loopBtn
        width: Style.space(36)
        height: Style.space(36)
        radius: width / 2
        anchors.verticalCenter: parent.verticalCenter
        color: (root.loopMode === "Playlist" || root.loopMode === "Track") ? root.brandGreenDim : (loopMouse.containsMouse ? Style.hoverFillFor(root.bar.foreground, Color.accent) : "transparent")

        Behavior on color { ColorAnimation { duration: 120 } }

        Text {
          anchors.centerIn: parent
          textFormat: Text.PlainText
          text: root.loopMode === "Track" ? "󰑘" : "󰑖"
          color: (root.loopMode === "Playlist" || root.loopMode === "Track") ? root.brandGreen : (loopMouse.containsMouse ? root.bar.foreground : Qt.rgba(root.bar.foreground.r, root.bar.foreground.g, root.bar.foreground.b, 0.6))
          font.family: root.bar ? root.bar.fontFamily : Style.font.family
          font.pixelSize: Style.font.iconLarge

          Behavior on color { ColorAnimation { duration: 120 } }
        }

        MouseArea {
          id: loopMouse
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: {
            root.loopMode = SpotifyModel.cycleLoop(root.player, root.loopMode, Util)
          }
        }
      }
    }

    // 3. PROGRESS BAR & TIMELINE (Matching Screenshot)
    SpotifyProgressSlider {
      id: progressSlider
      width: parent.width
      bar: root.bar
      position: root.localPosition
      duration: root.trackDuration
      isPlaying: root.isPlaying
      accentColor: root.brandGreen
      textColor: root.bar ? root.bar.foreground : Color.foreground

      onSeekRequested: function(targetSeconds) {
        root.localPosition = targetSeconds
        SpotifyModel.seekToPosition(root.player, targetSeconds, Util)
      }
    }

    PanelSeparator {
      width: parent.width
      foreground: root.bar.foreground
    }

    // 4. BOTTOM TRAY: VOLUME & QUICK ACTIONS
    Row {
      width: parent.width
      spacing: Style.space(10)

      // Volume Slider
      SpotifyVolumeSlider {
        id: volumeSlider
        width: Style.space(150)
        anchors.verticalCenter: parent.verticalCenter
        bar: root.bar
        volumeLevel: root.playerVolume
        accentColor: root.brandGreen
        textColor: root.bar ? root.bar.foreground : Color.foreground

        onAdjustVolume: function(newVol) {
          root.playerVolume = newVol
          SpotifyModel.setVolume(root.player, newVol, Util)
        }
      }

      Item {
        // Spacer
        width: parent.width - volumeSlider.width - actionsRow.width - Style.space(20)
        height: 1
      }

      // Quick Action Buttons
      Row {
        id: actionsRow
        anchors.verticalCenter: parent.verticalCenter
        spacing: Style.space(8)

        // Focus / Open Spotify Window
        BorderSurface {
          id: openAppBtn
          width: Style.space(30)
          height: Style.space(30)
          radius: width / 2
          color: openAppMouse.containsMouse ? Style.hoverFillFor(root.bar.foreground, Color.accent) : "transparent"
          borderSpec: Border.controlSpec("normal", root.bar.foreground, Color.accent)

          Text {
            anchors.centerIn: parent
            textFormat: Text.PlainText
            text: "󰓇"
            color: openAppMouse.containsMouse ? root.brandGreen : root.bar.foreground
            font.family: root.bar ? root.bar.fontFamily : Style.font.family
            font.pixelSize: Style.font.subtitle
          }

          MouseArea {
            id: openAppMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: SpotifyModel.raiseOrLaunchSpotify(root.player, Util)
          }
        }
      }
    }
  }

  // ==========================================
  // STATE B: SPOTIFY CLOSED / OFFLINE CARD
  // ==========================================
  Column {
    id: offlineColumn
    anchors.fill: parent
    spacing: Style.space(16)
    visible: !root.isConnected

    Item {
      width: parent.width
      height: Style.space(10)
    }

    // Centered Glowing Spotify Brand Icon
    Item {
      width: Style.space(64)
      height: Style.space(64)
      anchors.horizontalCenter: parent.horizontalCenter

      Rectangle {
        anchors.centerIn: parent
        width: parent.width + Style.space(12)
        height: parent.height + Style.space(12)
        radius: width / 2
        color: root.brandGreen
        opacity: 0.18

        SequentialAnimation on scale {
          loops: Animation.Infinite
          NumberAnimation { from: 1.0; to: 1.15; duration: 1400; easing.type: Easing.InOutQuad }
          NumberAnimation { from: 1.15; to: 1.0; duration: 1400; easing.type: Easing.InOutQuad }
        }
      }

      Text {
        anchors.centerIn: parent
        textFormat: Text.PlainText
        text: "󰓇"
        color: root.brandGreen
        font.family: root.bar ? root.bar.fontFamily : Style.font.family
        font.pixelSize: Style.font.displayLarge
      }
    }

    // Title & Info
    Column {
      width: parent.width
      spacing: Style.space(4)
      anchors.horizontalCenter: parent.horizontalCenter

      Text {
        textFormat: Text.PlainText
        text: "Spotify is not running"
        color: root.bar ? root.bar.foreground : Color.foreground
        font.family: root.bar ? root.bar.fontFamily : Style.font.family
        font.pixelSize: Style.font.heading
        font.weight: Font.Bold
        horizontalAlignment: Text.AlignHCenter
        width: parent.width
      }

      Text {
        textFormat: Text.PlainText
        text: "Launch Spotify to play your music, playlists, and podcasts."
        color: Qt.rgba(root.bar.foreground.r, root.bar.foreground.g, root.bar.foreground.b, 0.65)
        font.family: root.bar ? root.bar.fontFamily : Style.font.family
        font.pixelSize: Style.font.bodySmall
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WordWrap
        width: parent.width
      }
    }

    // Launch Spotify Hero Action Button
    BorderSurface {
      id: launchHeroBtn
      width: Style.space(180)
      height: Style.space(38)
      anchors.horizontalCenter: parent.horizontalCenter
      radius: Style.space(19)
      color: launchMouse.containsMouse ? root.brandGreenHover : root.brandGreen
      borderSpec: Border.controlSpec("normal", root.bar.foreground, Color.accent)
      scale: launchMouse.pressed ? 0.94 : (launchMouse.containsMouse ? 1.05 : 1.0)

      Behavior on scale {
        NumberAnimation { duration: 120; easing.type: Easing.OutBack }
      }

      Behavior on color {
        ColorAnimation { duration: 120 }
      }

      Row {
        anchors.centerIn: parent
        spacing: Style.space(8)

        Text {
          textFormat: Text.PlainText
          text: "󰐊"
          color: "#000000"
          font.family: root.bar ? root.bar.fontFamily : Style.font.family
          font.pixelSize: Style.font.body
          font.weight: Font.Bold
          anchors.verticalCenter: parent.verticalCenter
        }

        Text {
          textFormat: Text.PlainText
          text: "Launch Spotify"
          color: "#000000"
          font.family: root.bar ? root.bar.fontFamily : Style.font.family
          font.pixelSize: Style.font.body
          font.weight: Font.Bold
          anchors.verticalCenter: parent.verticalCenter
        }
      }

      MouseArea {
        id: launchMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: SpotifyModel.raiseOrLaunchSpotify(null, Util)
      }
    }

    Item {
      width: parent.width
      height: Style.space(4)
    }
  }
}
