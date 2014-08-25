class Utils
  @filterSymbols: (name) ->
    return name.replace(/[^\w]/gi, '')
