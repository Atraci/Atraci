menu = new gui.Menu(type: 'menubar')

# Language menu
l10nMenu = new gui.MenuItem(
  label: 'Languages'
  submenu: new gui.Menu()
)

changeLang = (menuItem, lang) ->
  l10nMenu.submenu.items.forEach((eachSubMenu) ->
    eachSubMenu.checked = false
  )
  menuItem.checked = true
  window.l10n.changeLang(lang)

[
  { label: 'English', lang: 'en', default: true },
  { label: '繁體中文', lang: 'zh-TW' },
  { label: 'עברית', lang: 'he-IL' },
  { label: 'Esperanto', lang: 'eo' },
  { label: 'Italiano', lang: 'it' },
  { label: 'slovenščina', lang: 'sl-SI' },
  { label: 'Español', lang: 'es-419' },
  { label: '日本語', lang: 'ja' },
  { label: 'Deutsch', lang: 'de' },
  { label: 'Afrikaans', lang: 'af-ZA' },
  { label: 'Bosanski', lang: 'bs-BA' },
  { label: 'Hrvatski', lang: 'hr-HR' },
  { label: 'Serbian', lang: 'sr' },
  { label: 'Français', lang: 'fr' },
  { label: 'Polski', lang: 'pl-PL' },
  { label: 'Português', lang: 'pt-BR' },
  { label: 'Български', lang: 'bg' },
  { label: 'Nederlands', lang: 'nl' },
  { label: 'العربية', lang: 'ar' }
].forEach((item) ->
  label = item.label
  lang = item.lang
  menuItem = new gui.MenuItem(
    label: label
    type: 'checkbox'
    click: ->
      changeLang(this, lang)
  )

  # select on the default one
  if item.default
    menuItem.checked = true

  l10nMenu.submenu.append menuItem
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
