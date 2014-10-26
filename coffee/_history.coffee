class History
  @clear: (success) ->
    db.history.remove({}, { multi: true }, (error) ->
      if error
        console.log("History.clear remove erorr :")
        console.log(error)
        success?()
      else
        success?()
    )

  @addTrack: (artist, title, cover_url_medium, cover_url_large) ->
    unix_timestamp = Math.round((new Date()).getTime() / 1000)
    db.history.remove({
      artist: artist,
      title: title
    }, {}, (error, numRemoved) ->
      if error
        console.log("History.addTrack remove erorr :")
        console.log(error)
      else
        db.history.insert({
          artist: artist,
          title: title,
          cover_url_medium: cover_url_medium,
          cover_url_large: cover_url_large,
          last_played: unix_timestamp
        }, (error) ->
          if error
            console.log("History.addTrack insert erorr :")
            console.log(error)
        )
    )

  @removeTrack: (artist, title) ->
    db.history.remove({
      artist: artist,
      title: title
    }, {}, (error) ->
      if error
        console.log("History.removeTrack remove erorr :")
        console.log(error)
    )

  @getTracks: (success) ->
    db.history.find({}).sort({
      last_played: -1
    }).limit(150).exec((error, foundTracks) ->
      if error
        console.log("History.getTracks find erorr :")
        console.log(error)
        success?([])
      else
        success?(foundTracks)
    )

  @countTracks: (success) ->
    db.history.count({}, (error, count) ->
      if error
        console.log("History.countTracks count erorr :")
        console.log(error)
        success?(0)
      else
        success?(count)
    )
