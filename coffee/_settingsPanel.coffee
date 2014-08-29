# global Playlists, History, win

class SettingsPanel
  constructor: ->
    # Selectors
    @settingsPanel = $('#settings-panel')
    @settingsBtn = $('#Settings .settings')
    @devToolsBtn = $('.devTools')
    @clearCacheBtn = $('.clearCache')
    @resetDatabaseBtn = $('.resetDatabase')
    @languageSelect = $('#LanguageSelect')
    @themeSelect = $('#ThemeSelect')
    @positionTarget = $('body')

    @bindEvents()
    @initDialog()
    @initL10nOptions()

  bindEvents: ->
    @settingsBtn.on 'click', =>
      if @settingsPanel.is ':hidden'
        @show()
      else
        @close()

    @devToolsBtn.on 'click', =>
      win.showDevTools()
      @close()

    @clearCacheBtn.on 'click', =>
      @close()
      win.reloadIgnoringCache()

    @resetDatabaseBtn.on 'click', =>
      @close()
      Playlists.clear ->
        History.clear ->
          win.reloadIgnoringCache()

  initDialog: ->
    @settingsPanel.dialog
      autoOpen: false,
      height: 375,
      width: 350,
      position:
        of: @positionTarget
      show:
        effect: 'blind',
        duration: 500
      hide:
        effect: 'blind',
        duration: 500
      title: 'Settings',
      modal: true,
      dialogClass: 'settingsClass',
      buttons:
        'Cancel': =>
          @close()
        ,
        'Save': =>
          window.l10n.changeLang(@languageSelect.val())
          window.theme.changeTheme(@themeSelect.val())
          @close()

  initL10nOptions: ->
    window.l10n.getSupportedLanguages((data) =>
      if !data
        return

      options = []
      languages = data.languages
      languages.forEach((language) ->
        option = $('<option>')
        option.prop('value', language.lang)
        option.text(language.label)

        if language.default
          option.prop('selected', true)

        options.push(option)
      )
      @languageSelect.append(options)
    )

  reposition: ->
    @settingsPanel.dialog('option', 'position',
      of: @positionTarget
    )

  close: ->
    @settingsPanel.dialog 'close'

  show: ->
    @settingsPanel.dialog 'open'

  toggle: ->
    isOpen = @settingsPanel.dialog 'isOpen'
    if isOpen
      @close()
    else
      @show()
