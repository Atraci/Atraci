# Based on jQuery
class Theme
  constructor: ->
    @currentTheme = Settings.get("theme")
    @callbacks = []

    if @currentTheme
      $("body").attr("class", "").addClass(@currentTheme + "Theme")

    @setSelectActiveTheme()

  changeTheme: (theme) ->
    if theme
      @currentTheme = theme
      $("body").attr("class", "").addClass(@currentTheme + "Theme")
      Settings.set("theme", theme)

  setSelectActiveTheme: ->
    $("#ThemeSelect option[value="+@currentTheme+"]")
      .attr("selected","selected")