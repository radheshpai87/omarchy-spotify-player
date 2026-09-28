// Helper library for Omarchy Spotify Extension
// Handles MPRIS player discovery, track parsing, D-Bus fallback commands, duration formatting, and playback states.

.pragma library

// Format seconds into "M:SS" or "H:MM:SS"
function formatTime(totalSeconds) {
  if (totalSeconds === undefined || totalSeconds === null || isNaN(totalSeconds) || totalSeconds < 0) {
    return "0:00"
  }
  var s = Math.floor(totalSeconds)
  var hours = Math.floor(s / 3600)
  var minutes = Math.floor((s % 3600) / 60)
  var seconds = s % 60

  var paddedSeconds = seconds < 10 ? "0" + seconds : String(seconds)
  if (hours > 0) {
    var paddedMinutes = minutes < 10 ? "0" + minutes : String(minutes)
    return hours + ":" + paddedMinutes + ":" + paddedSeconds
  }
  return minutes + ":" + paddedSeconds
}

// Find Spotify player from Quickshell Mpris.players array
function findSpotifyPlayer(players) {
  if (!players || players.length === 0) return null

  // 1. Exact match for Spotify
  for (var i = 0; i < players.length; i++) {
    var p = players[i]
    if (!p) continue
    var dbusName = String(p.dbusName || "").toLowerCase()
    var identity = String(p.identity || "").toLowerCase()
    var desktop = String(p.desktopEntry || "").toLowerCase()

    if (dbusName.indexOf("spotify") !== -1 || identity.indexOf("spotify") !== -1 || desktop.indexOf("spotify") !== -1) {
      return p
    }
  }

  // 2. Any active player playing music if Spotify not specifically found
  for (var j = 0; j < players.length; j++) {
    var player = players[j]
    if (player && player.isPlaying && (player.trackTitle || player.trackArtist)) {
      return player
    }
  }

  // 3. Any player with metadata
  for (var k = 0; k < players.length; k++) {
    var pl = players[k]
    if (pl && (pl.trackTitle || pl.trackArtist)) {
      return pl
    }
  }

  return players.length > 0 ? players[0] : null
}

// Check if a player is Spotify
function isSpotify(player) {
  if (!player) return false
  var dbusName = String(player.dbusName || "").toLowerCase()
  var identity = String(player.identity || "").toLowerCase()
  var desktop = String(player.desktopEntry || "").toLowerCase()
  return dbusName.indexOf("spotify") !== -1 || identity.indexOf("spotify") !== -1 || desktop.indexOf("spotify") !== -1
}

// Get player DBus destination
function playerDbusDest(player) {
  if (!player) return "org.mpris.MediaPlayer2.spotify"
  if (player.dbusName && String(player.dbusName).length > 0) {
    return String(player.dbusName)
  }
  return "org.mpris.MediaPlayer2.spotify"
}

// Execute DBus command with busctl
function runDbus(utilOrQuickshell, args) {
  try {
    if (utilOrQuickshell && typeof utilOrQuickshell.execDetached === "function") {
      utilOrQuickshell.execDetached(["busctl", "--user"].concat(args))
    }
  } catch (e) {
    console.warn("Spotify DBus exec failed:", e)
  }
}

// Toggle Play / Pause
function togglePlayPause(player, util) {
  if (player) {
    if (player.canTogglePlaying) {
      player.togglePlaying()
      return
    }
    if (player.isPlaying && player.canPause) {
      player.pause()
      return
    }
    if (!player.isPlaying && player.canPlay) {
      player.play()
      return
    }
  }
  // Fallback via DBus
  var dest = playerDbusDest(player)
  runDbus(util, ["call", dest, "/org/mpris/MediaPlayer2", "org.mpris.MediaPlayer2.Player", "PlayPause"])
}

// Skip Next
function nextTrack(player, util) {
  if (player && player.canGoNext) {
    player.next()
    return
  }
  var dest = playerDbusDest(player)
  runDbus(util, ["call", dest, "/org/mpris/MediaPlayer2", "org.mpris.MediaPlayer2.Player", "Next"])
}

// Skip Previous
function previousTrack(player, util) {
  if (player && player.canGoPrevious) {
    player.previous()
    return
  }
  var dest = playerDbusDest(player)
  runDbus(util, ["call", dest, "/org/mpris/MediaPlayer2", "org.mpris.MediaPlayer2.Player", "Previous"])
}

// Toggle Shuffle
function toggleShuffle(player, currentShuffleState, util) {
  var nextState = !currentShuffleState
  if (player && "shuffle" in player) {
    try {
      player.shuffle = nextState
    } catch (e) {}
  }
  var dest = playerDbusDest(player)
  runDbus(util, ["set-property", dest, "/org/mpris/MediaPlayer2", "org.mpris.MediaPlayer2.Player", "Shuffle", "b", nextState ? "true" : "false"])
  return nextState
}

// Cycle Loop / Repeat (None -> Playlist -> Track -> None)
function cycleLoop(player, currentLoopState, util) {
  var nextState = "None"
  var current = String(currentLoopState || "None")

  if (current === "None" || current === "0") {
    nextState = "Playlist"
  } else if (current === "Playlist" || current === "2") {
    nextState = "Track"
  } else {
    nextState = "None"
  }

  if (player && "loopState" in player) {
    try {
      player.loopState = nextState
    } catch (e) {}
  }
  var dest = playerDbusDest(player)
  runDbus(util, ["set-property", dest, "/org/mpris/MediaPlayer2", "org.mpris.MediaPlayer2.Player", "LoopStatus", "s", nextState])
  return nextState
}

// Seek / Set Position
function seekToPosition(player, targetSeconds, util) {
  if (targetSeconds === undefined || targetSeconds === null || isNaN(targetSeconds)) return

  var targetUs = Math.floor(Math.max(0, targetSeconds) * 1000000)
  var trackId = "/org/mpris/MediaPlayer2/TrackList/NoTrack"

  if (player && player.metadata) {
    if (player.metadata["mpris:trackid"]) {
      trackId = String(player.metadata["mpris:trackid"])
    }
  }

  // Try Quickshell native first
  if (player && "position" in player) {
    try {
      player.position = targetSeconds
    } catch (e) {}
  }

  // Also call DBus SetPosition for 100% reliability
  var dest = playerDbusDest(player)
  runDbus(util, ["call", dest, "/org/mpris/MediaPlayer2", "org.mpris.MediaPlayer2.Player", "SetPosition", "ox", trackId, String(targetUs)])
}

// Set Volume (0.0 to 1.0)
function setVolume(player, volumeLevel, util) {
  var clamped = Math.max(0, Math.min(1.0, volumeLevel))
  if (player && "volume" in player) {
    try {
      player.volume = clamped
    } catch (e) {}
  }
  var dest = playerDbusDest(player)
  runDbus(util, ["set-property", dest, "/org/mpris/MediaPlayer2", "org.mpris.MediaPlayer2.Player", "Volume", "d", String(clamped)])
}

// Raise / Launch Spotify Application
function raiseOrLaunchSpotify(player, util) {
  if (util && typeof util.execDetached === "function") {
    var cmd = 'if hyprctl clients -j 2>/dev/null | jq -e \'.[] | select((.class // "") | test("^[Ss]potify$"))\' >/dev/null 2>&1; then ' +
              'hyprctl dispatch movetoworkspace "current,initialClass:spotify" >/dev/null 2>&1 && ' +
              'hyprctl dispatch focuswindow "initialClass:spotify" >/dev/null 2>&1; ' +
              'else ' +
              'spotify >/dev/null 2>&1 & ' +
              'fi'
    util.execDetached(["bash", "-c", cmd])
  } else if (player && player.canRaise) {
    player.raise()
  }
}
