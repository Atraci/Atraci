# Based on jQuery
class L10n
  constructor: (defaultLang) ->
    @cachedStrings = {}
    @currentLang = defaultLang or 'en'
    @folder = 'l10n/'
    @l10nFileSuffix = '.ini'
    @metadataPath = 'metadata.json'
    @callbacks = []

  getSupportedLanguages: (cb) ->
    $.ajax(
      url: @folder + @metadataPath,
      dataType: 'json'
    ).done((metadata) ->
      cb(metadata)
    ).fail((error) ->
      console.error(error)
      cb(null)
    )

  fetchIniData: (cb) ->
    if @cachedStrings[@currentLang]
      cb()
    else
      $.ajax(
        url: @folder + @currentLang + @l10nFileSuffix,
      ).done((iniData) =>
        @cachedStrings[@currentLang] = @parseInI(iniData)
        cb()
      ).fail((error) ->
        console.error(error)
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

      reLine = /(\w+)\s*=\s*["]?(.*?)["]?$/
      matched = reLine.exec(eachLine)
      matchedKey = matched and matched[1]
      matchedValue = matched and matched[2]

      if matchedKey and matchedValue
        result[matchedKey] = matchedValue
    )
    return result

  get: (l10nId, params, fallbackToEn) ->
    lang = @currentLang

    # We may not find new-added string, so let's fallback to english
    if fallbackToEn
      lang = 'en'

    translatedString = @cachedStrings[lang][l10nId]

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
      console.log("""
        You are accessing non-existent l10nId : #{l10nId}, lang: #{@currentLang}
      """)
      return @get(l10nId, params, true)
    else
      return translatedString

  addEventListener: (eventName, callback) ->
    if eventName is 'localizationchange'
      @callbacks.push callback

  removeEventListener: (eventName, callback) ->
    if eventName is 'localizationchange'
      callbackIndex = @callbacks.indexOf(callback)
      if callbackIndex >= 0
        @callbacks.splice(callbackIndex, 1)

  changeLang: (lang) ->
    if lang
      @currentLang = lang

    @fetchIniData(() =>
      @callbacks.forEach((callback) ->
        callback()
      )
    )
