( ->
  request = require('request')
  ytdl = require('ytdl')

  class Requestor
    @get: (options, cb) ->
      # We have to put it under node's context first
      global.setTimeout( ->
        request options, cb
      , 0)

    @getYoutubeInfo: (link, options, cb) ->
      # We have to put it under node's context first
      global.setTimeout( ->
        ytdl.getInfo link, options, cb
      , 0)

  window.Requestor = Requestor
)()
