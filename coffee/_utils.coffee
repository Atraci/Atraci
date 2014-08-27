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
