# Load native UI library
gui = require('nw.gui')

# Get auto update libraries
pkg = require('../package.json')
updater = require('node-webkit-updater')
upd = new updater(pkg)

# Get window object (!= $(window))
win = gui.Window.get()

# Debug flag
isDebug = true

# Set the app title (for Windows mostly)
win.title = gui.App.manifest.name + ' ' + gui.App.manifest.version

# Focus the window when the app opens
win.focus()

# Show the window when the app opens
win.show()

# Open Web SQL Database
# https://github.com/rogerwang/node-webkit/wiki/Save-persistent-data-in-app
db = openDatabase('AtraciDB', '1.0', '', 10 * 1024 * 1024)

# Cancel all new windows (Middle clicks / New Tab)
win.on "new-win-policy", (frame, url, policy) ->
  policy.ignore()

# Prevent dragging/dropping files into/outside the window
preventDefault = (e) ->
  e.preventDefault()

window.addEventListener "dragover", preventDefault, false
window.addEventListener "drop", preventDefault, false
window.addEventListener "dragstart", preventDefault, false

# For mac, add basic menu back
if process.platform is 'darwin'
  defaultMenu = new gui.Menu({ type: 'menubar' })
  defaultMenu.createMacBuiltin(gui.App.manifest.name)
  win.menu = defaultMenu

# Spinner options (should go in config file).
# Should replace spinner by rotating svg later
spinner_opts =
  lines: 10 # The number of lines to draw
  length: 8 # The length of each line
  width: 3 # The line thickness
  radius: 8 # The radius of the inner circle
  color: '#aaa' # #rgb or #rrggbb or array of colors
  speed: 2 # Rounds per second

spinner_cover_opts =
  lines: 8 # The number of lines to draw
  length: 5 # The length of each line
  width: 2 # The line thickness
  radius: 6 # The radius of the inner circle
  color: '#fff' # #rgb or #rrggbb or array of colors
  speed: 2 # Rounds per second


########################################################

$ ->
  window.l10n = new L10n
  window.theme = new Theme
  window.windowManager = new WindowManager
  window.settingsPanel = new SettingsPanel
  window.tracklist = new Tracklist
  window.sidebar = new Sidebar
  window.playlistPanel = new PlaylistPanel

  #Initialize the playlists DB
  setTimeout( ->
    Playlists.initDB()
  , 1000)

  splash = gui.Window.open 'splash.html', {
    position: 'center',
    width: 600,
    height: 300,
    frame: false,
    toolbar: false
  }

  windowManager.setWindowLocationOnScreen()

  setTimeout ->
    $(".blackScreen").remove()
    splash.close()
  , 2000

#provide a resizeend event
  timer = window.setTimeout ->
    ,
    0

  $(window).on 'resize', ->
    window.clearTimeout(timer)
    timer =
      window.setTimeout ->
        settingsPanel.reposition()
      ,100

  $(window).on 'resize', ->
    clearTimeout addghost
    addghost = setTimeout( ->
      window.tracklist.calculateDivsInRow()
    , 100)

  # Make sure we would update strings when localization event is emitted
  l10n.addEventListener 'localizationchange', () ->
    $elements = $('[data-l10n-id]')
    $elements.each((index, ele) ->
      $ele = $(ele)
      l10nId = $ele.data('l10n-id')
      params = $ele.data('l10n-params')

      if $ele.attr('title') isnt undefined
        $ele.attr('title', l10n.get(l10nId, params))
      else if $ele.attr('placeholder') isnt undefined
        $ele.attr('placeholder', l10n.get(l10nId, params))
      else
        $ele.text(l10n.get(l10nId, params))
    )

  l10n.changeLang()

  $("#tracklistSorter").change ->
    window.tracklist.populate(
      window.tracklist.getCurrentTracklist(),
      null,
      true
    )

   # create sidebar related stuffs
  sidebar.populateFeaturedMusic()
  Playlists.getAll((playlists) ->
    sidebar.populatePlaylists(playlists)
  )

  # We will show top tracks when bootup
  setTimeout ( ->
    History.countTracks(() ->
      $('#SideBar li.top').click()
    )
  ), 1

  $('#Search input').focus()

  # Check for version update
  # Linux and Windows only so far. Mac coming up soon
  if getOperatingSystem() is "windows" or "linux"
    upd.checkNewVersion (error, manifest) ->
      if error is null
        alertify.confirm l10n.get('confirm_update'), (e) ->
          if e
            alertify.log l10n.get('downloading')
            upgradeNow manifest, (filename) ->
              console.log "Done"
              if getOperatingSystem() is "windows"
                setTimeout ->
                  upd.run(filename)
                , 400
              if getOperatingSystem() is "linux"
                tarball = require('tarball-extract')
                tarball.extractTarball(filename, upd.getAppPath() + "/latest"
                , (error) ->
                  if error?
                    console.log "path" + error
                  else
                    alertify.log l10n.get('linux_complete')
                )

    upgradeNow = (newManifest, cb) ->
      newVersion = upd.download (error, filename) ->
        console.log "Saved to : " + filename
        if error is null
          console.log "Current app in: " + upd.getAppPath() +
          "on " + getOperatingSystem()
          cb filename
      , newManifest
  true