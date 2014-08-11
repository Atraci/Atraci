class SettingsPanel
  constructor: ->
    # Selectors
    @settingsPanel = $('#settings-panel')
    @settingsBtn = $('#Settings .settings')
    @devToolsBtn = $('.devTools')
    @clearCacheBtn = $('.clearCache')
    @resetDatabaseBtn = $('.resetDatabase')
    @languageSelect = $('#LanguageSelect')
    @positionTarget = $('body')

    @bindEvents()
    @initDialog()

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
      height: 340,
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
          @close()

  reposition: ->
    @settingsPanel.dialog('option', 'position',
      of: @positionTarget
    )

  close: ->
    @settingsPanel.dialog 'close'

  show: ->
    @settingsPanel.dialog 'open'
