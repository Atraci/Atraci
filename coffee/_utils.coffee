class Utils
  @filterSymbols: (name) ->
    return name.replace(/([.*+?^=!:${}()|\[\]\/\\ ])/g, '')

  @getYoutubePlaylistId: (link) ->
    re = ///
      ^.*(youtu.be\/|list=)
      ([^#\&\?]*).*
    ///
    match = link.match(re)
    if match and match[2]
      return match[2]
    else
      return undefined

  @createRandomPlaylistName: (playlistId = '') ->
    randomId = playlistId.split('').sort(() ->
      return 0.5 - Math.random()
    ).join('')

    return l10n.get('playlist') + '-' + randomId.substr(0, 5)
