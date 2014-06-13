if isDebug
    menu = new gui.Menu(type: 'menubar')

    menu.append new gui.MenuItem(
        label: 'Tools'
        submenu: new gui.Menu()
    )

    menu.items[0].submenu.append new gui.MenuItem(
        label: 'Developer Tools'
        click: ->
            win.showDevTools()
    )

    menu.items[0].submenu.append new gui.MenuItem(
        label: "Reload ignoring cache"
        click: ->
            win.reloadIgnoringCache()
    )

    menu.items[0].submenu.append new gui.MenuItem(
        label: "Reset database"
        click: ->
            Playlists.clear ->
                History.clear ->
                    win.reloadIgnoringCache()
    )

    win.menu = menu