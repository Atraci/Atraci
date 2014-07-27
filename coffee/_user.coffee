request = require('request')

class User
  @_cachedUserInfo: null

  @getRightCountyCode: (countryCode) ->
    switch countryCode
      when 'TW' then return 'zh-TW'
      else return 'unknown'

  @getInfo: (success) ->
    if @_cachedUserInfo isnt null
      success? @_cachedUserInfo
    else
      # we will use user's ip to know where (s)he is
      request
        url: 'http://ip-api.com/json',
        json: true
      , (error, response, data) =>
        if not error and response.statusCode is 200
          @_cachedUserInfo = {}
          @_cachedUserInfo.country = data.country
          @_cachedUserInfo.countryCode = @getRightCountyCode(data.countryCode)
          @_cachedUserInfo.timezone = data.timezone
          @_cachedUserInfo.lat = data.lat
          @_cachedUserInfo.lon = data.lon
          @_cachedUserInfo.ip = data.query

        success? @_cachedUserInfo
