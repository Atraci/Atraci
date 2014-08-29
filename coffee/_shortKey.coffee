( ->
  toggleTrack = ->
    if videojs('video_player').paused()
      videojs('video_player').play()
    else
      videojs('video_player').pause()

  playNextTrack = ->
    PlayNext(__currentTrack.artist, __currentTrack.title)

  playPrevTrack = ->
    PlayPrevious(__currentTrack.artist, __currentTrack.title)

  # Keyboard control : space : play / pause arrows : previous / next
  $(document).keydown (e) ->
    # space
    if e.keyCode is 32 and e.target.tagName != 'INPUT'
      e.preventDefault()
      toggleTrack()

    # left arrow
    if e.keyCode is 37 and e.target.tagName != 'INPUT'
      playPrevTrack()

    # right arrow
    if e.keyCode is 39 and e.target.tagName != 'INPUT'
      playNextTrack()

  # special keys bound by node-webkit
  toggleTrackKey = new gui.Shortcut({
    key: 'MediaPlayPause',
    active: ->
      toggleTrack()
  })

  playNextTrackKey = new gui.Shortcut({
    key: 'MediaNextTrack'
    active: ->
      playNextTrack()
  })

  playPrevTrackKey = new gui.Shortcut({
    key: 'MediaPrevTrack'
    active: ->
      playPrevTrack()
  })

  gui.App.registerGlobalHotKey(toggleTrackKey)
  gui.App.registerGlobalHotKey(playNextTrackKey)
  gui.App.registerGlobalHotKey(playPrevTrackKey)

  if process.platform is 'darwin'
    openSettingsKey = new gui.Shortcut({
      key: 'Ctrl+Comma'
      active: ->
        window.settingsPanel.toggle()
    })
    gui.App.registerGlobalHotKey(openSettingsKey)
)()
