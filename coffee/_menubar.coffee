menu = new gui.Menu(type: 'menubar')

# Language menu
l10nMenu = new gui.MenuItem(
    label: 'Language'
    submenu: new gui.Menu()
)

changeLang = (menuItem, lang) ->
    l10nMenu.submenu.items.forEach((eachSubMenu) ->
        eachSubMenu.checked = false
    )
    menuItem.checked = true
    window.l10n.changeLang(lang)

[
    { label: 'English', lang: 'en' },
    { label: '繁體中文', lang: 'zh-TW' },
    { label: 'עברית', lang: 'he-IL' },
    { label: 'Esperanto', lang: 'eo' },
    { label: 'Italiano', lang: 'it' },
    { label: 'slovenščina', lang: 'sl-SI' },
    { label: 'Español', lang: 'es-419' },
    { label: '日本語', lang: 'ja' }
].forEach((item) ->
  label = item.label
  lang = item.lang
  l10nMenu.submenu.append new gui.MenuItem(
      label: label
      type: 'checkbox'
      click: ->
          changeLang(this, lang)
  )
)

menu.append l10nMenu

# Debug menu
if isDebug
    debugMenu = new gui.MenuItem(
        label: 'Tools'
        submenu: new gui.Menu()
    )

    debugMenu.submenu.append new gui.MenuItem(
        label: 'Developer Tools'
        click: ->
            win.showDevTools()
    )

    debugMenu.submenu.append new gui.MenuItem(
        label: "Reload ignoring cache"
        click: ->
            win.reloadIgnoringCache()
    )

    debugMenu.submenu.append new gui.MenuItem(
        label: "Reset database"
        click: ->
            Playlists.clear ->
                History.clear ->
                    win.reloadIgnoringCache()
    )

    menu.append debugMenu

# put menu back in win
win.menu = menu
