class WindowManager
  constructor: ->
    @isMaximized = false
    @expandBtn = $('#WindowButtons .Expand')
    @closeBtn = $('#WindowButtons .Close')
    @minimizeBtn = $('#WindowButtons .Minimize')
    @toolbarBtns = $('.trackListToolbar i')
    @contentWrapper = $('#ContentWrapper')

    @bindEvents()

  bindEvents: ->
    self = @
    @expandBtn.on 'click', =>
      if !@isMaximized
        @isMaximized = true
        @maximize()
      else
        @isMaximized = false
        @unmaximize()

    @closeBtn.on 'click', =>
      @saveWindowLocationOnScreen()
      @close()

    @minimizeBtn.on 'click', =>
      @minimize()

    @toolbarBtns.on 'click', ->
      self.toolbarBtns.removeClass('active')
      $(@).addClass('active')
      if $(@).hasClass('fa-th')
        self.contentWrapper.removeClass('smallRows')
      else
        self.contentWrapper.addClass('smallRows')

  minimize: ->
    win.minimize()

  maximize: ->
    win.maximize()

  unmaximize: ->
    win.unmaximize()

  close: ->
    win.close()

  saveWindowLocationOnScreen: ->
    Settings.set("windowLocationX", gui.Window.get().x)
    Settings.set("windowLocationY", gui.Window.get().y)

  setWindowLocationOnScreen: ->
    gui.Window.get().x = Settings.get("windowLocationX")
    gui.Window.get().y = Settings.get("windowLocationY")