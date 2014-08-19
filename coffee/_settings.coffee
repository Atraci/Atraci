Settings =
  get: (variable) ->
    localStorage['settings_' + variable]
  set: (variable, newValue) ->
    localStorage.setItem 'settings_' + variable, newValue
  init: ->
    if not @get('updateUrl')
      @set('updateUrl', 'http://getatraci.net/update.json')

Settings.init()
