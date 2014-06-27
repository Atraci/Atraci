# Based on jQuery
class L10n
  constructor: (defaultLang) ->
    @cachedStrings = {}
    @currentLang = defaultLang or 'en'
    @folder = 'l10n/'
    @l10nFileSuffix = '.ini'
    @fetchIniData(->)

  fetchIniData: (cb) ->
    if @cachedStrings[@currentLang]
      cb()
    else 
      $.ajax(
        url: @folder + @currentLang + @l10nFileSuffix,
      ).done((iniData) =>
        @cachedStrings[@currentLang] = @parseInI(iniData)
        cb()
      )

  parseInI: (data) ->
    result = {}
    lines = data.split(/\r\n|\r|\n/)
    lines.forEach((eachLine) ->
      eachLine = eachLine.trim()

      if eachLine.length == 0
        return
      
      if eachLine.charAt(0) == '#' || eachLine.charAt(0) == ';'
        return

      reLine = /(\w+)\s*=\s*(.*)$/
      matched = reLine.exec(eachLine)
      matchedKey = matched and matched[1]
      matchedValue = matched and matched[2]

      if matchedKey and matchedValue
        result[matchedKey] = matchedValue
    )
    return result

  get: (l10nId, params) ->
    translatedString = @cachedStrings[@currentLang][l10nId]

    reBracket = /\{\{\s*(\w+)\s*\}\}/g
    matched = false
    translate = () ->
      matchedBracketSubject = matched and matched[0]
      matchedParamKey = matched and matched[1]

      if matchedBracketSubject and matchedParamKey
        replaced = params[matchedParamKey]
        if replaced
          translatedString = 
            translatedString.replace(matchedBracketSubject, replaced)

    translate() while matched = reBracket.exec(translatedString)

    if not translatedString
      throw new Error('You are accessing non-existent l10nId :' + l10nId)
    else
      return translatedString
    
  changeLang: (lang) ->
    @currentLang = lang
    @fetchIniData(->
      $elements = $('[data-l10n-id]')
      $elements.each((index, $ele) =>
        l10nId = $ele.data('l10n-id')
        params = $ele.data('l10n-params')
        $ele.text(@get(l10nId, params))
      )
    )
