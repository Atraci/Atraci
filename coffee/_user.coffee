class User
  @_cachedUserInfo: null

  @getInfo: (success) ->
    if @_cachedUserInfo isnt null
      success? @_cachedUserInfo
    else
      # we will use user's ip to know where (s)he is
      $.getJSON('http://ip-api.com/json').done((data) ->
        @_cachedUserInfo = {}
        @_cachedUserInfo.country = data.country?.toLowerCase()
        @_cachedUserInfo.countryCode = data.countryCode
        @_cachedUserInfo.timezone = data.timezone
        @_cachedUserInfo.lat = data.lat
        @_cachedUserInfo.lon = data.lon
        @_cachedUserInfo.ip = data.query
        success? @_cachedUserInfo
      ).fail((jqXHR, status, error) ->
        console.log status
        console.log error
      )
