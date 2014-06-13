# Load native UI library
gui = require('nw.gui')

# Get window object (!= $(window))
win = gui.Window.get()

# Debug flag
isDebug = true

# Set the app title (for Windows mostly)
win.title = gui.App.manifest.name + ' ' + gui.App.manifest.version

# Focus the window when the app opens
win.focus()

# Open Web SQL Database
# https://github.com/rogerwang/node-webkit/wiki/Save-persistent-data-in-app#wiki-web-sql-database
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
    
    # Resize sidebar and tracklist heights when window is being resized
    $(window).resize(->
        $('#main #sidebar-container, #tracklist-container').height($(window).height() - ($('#header').outerHeight() + $('#player-container').outerHeight() + 20))
    ).resize()

    Playlists.getAll((playlists) ->
        populateSidebar(playlists)
        )

    setTimeout (->
        History.countTracks((cnt) ->
            if cnt > 10
                $('#sidebar-container li.history').click()
            else
                $('#sidebar-container li.top').click()
        )
    ), 1

    $('#search-input').focus()

    $("#ActionButtonExpand").click(()->
      if !$(this).hasClass("maximized")
        $(this).addClass("maximized")
        win.maximize()
      else
        $(this).removeClass("maximized")
        win.unmaximize()
    )

    $("#ActionButtonClose").click(()->
      win.close()
    )

    $("#ActionButtonMinimize").click(()->
      win.minimize()
    )

    true

