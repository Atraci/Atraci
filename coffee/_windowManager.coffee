class WindowManager
  constructor: ->
    @isMaximized = false
    @expandBtn = $('#WindowButtons .Expand')
    @closeBtn = $('#WindowButtons .Close')
    @minimizeBtn = $('#WindowButtons .Minimize')

    @bindEvents()

  bindEvents: ->
    @expandBtn.on 'click', =>
      if !@isMaximized
        @isMaximized = true
        @maximize()
      else
        @isMaximized = false
        @unmaximize()

    @closeBtn.on 'click', =>
      @close()

    @minimizeBtn.on 'click', =>
      @minimize()

  minimize: ->
    win.minimize()

  maximize: ->
    win.maximize()

  unmaximize: ->
    win.unmaximize()

  close: ->
    win.close()
