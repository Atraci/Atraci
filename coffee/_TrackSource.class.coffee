request = require('request')

class TrackSource
  @search: (keywords, success) ->
    tracks_all = {
      "itunes": []
      "lastfm": []
      "soundcloud": []
    }

    mashTracks = ->
      tracks_allconcat = tracks_all['itunes'].concat(
        tracks_all['lastfm'], tracks_all['soundcloud']
      )
      tracks_deduplicated = []
      tracks_hash = []
      $.each tracks_allconcat, (i, track) ->
        if track
          if track.artist and track.title
            track_hash =
              track.artist.toLowerCase() + '___' + track.title.toLowerCase()
            if track_hash not in tracks_hash
              tracks_deduplicated.push(track)
              tracks_hash.push(track_hash)
      success? tracks_deduplicated

    # itunes
    request
      url:
        'http://itunes.apple.com/search?media=music' +
        '&entity=song&limit=100&term=' + encodeURIComponent(keywords)
      json: true
    , (error, response, data) ->
      if not error and response.statusCode is 200
        tracks = []
        try
          $.each data.results, (i, track) ->
            tracks.push
              title: track.trackCensoredName
              artist: track.artistName
              cover_url_medium: track.artworkUrl60
              cover_url_large: track.artworkUrl100
        tracks_all['itunes'] = tracks
        if Object.keys(tracks_all).length > 1
          mashTracks()

    # last.fm
    request
      url:
        'http://ws.audioscrobbler.com/2.0/?method=track.search' +
        '&api_key=c513f3a2a2dad1d1a07021e181df1b1f&format=json&track=' +
        encodeURIComponent(keywords)
      json: true
    , (error, response, data) ->
      if not error and response.statusCode is 200
        tracks = []
        try
          if data.results.trackmatches.track.name
            data.results.trackmatches.track = [data.results.trackmatches.track]

          $.each data.results.trackmatches.track, (i, track) ->
            cover_url_medium =
              cover_url_large =
                'images/cover_default_large.png'
            if track.image
              $.each track.image, (i, image) ->
                if image.size == 'medium' and image['#text'] != ''
                  cover_url_medium = image['#text']
                else if image.size == 'large' and image['#text'] != ''
                  cover_url_large = image['#text']
            tracks.push
              title: track.name
              artist: track.artist
              cover_url_medium: cover_url_medium
              cover_url_large: cover_url_large
        tracks_all['lastfm'] = tracks
        if Object.keys(tracks_all).length > 1
          mashTracks()

    # Soundcloud
    request
      url:
        'https://api.soundcloud.com/tracks.json?' +
        'client_id=dead160b6295b98e4078ea51d07d4ed2&q=' +
        encodeURIComponent(keywords)
      json: true
    , (error, response, data) ->
      tracks = []
      $.each data, (i, track) ->
        if track
          trackNameExploded = track.title.split(" - ")
          coverPhoto = track.artwork_url
          coverPhoto = 'images/cover_default_large.png' if !track.artwork_url
          tracks.push
            title: trackNameExploded[0]
            artist: trackNameExploded[1]
            cover_url_medium: coverPhoto
            cover_url_large: coverPhoto

      tracks_all['soundcloud'] = tracks
      if Object.keys(tracks_all).length > 1
        mashTracks()

  # We will cache feature tracks in this object
  @_cachedFeaturedMusic: {}
  @featuredMusic: (playlistId, success) ->
    if @_cachedFeaturedMusic[playlistId] isnt undefined
      success? @_cachedFeaturedMusic[playlistId]
    else
      request
        url:
          'http://gdata.youtube.com/feeds/api/playlists/' + playlistId +
          '?start-index=1&amp;max-results=25&amp;v=2&alt=json'
        json: true
      , (error, response, data) =>
        tracks = []
        if not error and response.statusCode is 200
          $.each(data.feed.entry, (i, track) ->
            tracks.push
              title: track['media$group']['media$title']['$t']
              artist: track['author'][0]['name']['$t']
              cover_url_medium: track['media$group']['media$thumbnail'][1].url
              cover_url_large: track['media$group']['media$thumbnail'][0].url
          )
        @_cachedFeaturedMusic[playlistId] = tracks
        success? @_cachedFeaturedMusic[playlistId]

  # We will cache feature tracks in this array
  @_cachedTopTracks: []
  @topTracks: (success) ->
    if @_cachedTopTracks.length > 0
      success? @_cachedTopTracks
    else
      request
        url: 'http://itunes.apple.com/rss/topsongs/limit=100/explicit=true/json'
        json: true
      , (error, response, data) =>
        if not error and response.statusCode is 200
          tracks = []
          tracks_hash = []
          $.each data.feed.entry, (i, track) ->
            track_hash =
              track['im:artist'].label + '___' + track['im:name'].label
            if track_hash not in tracks_hash
              tracks.push
                title: track['im:name'].label
                artist: track['im:artist'].label
                cover_url_medium: track['im:image'][1].label
                cover_url_large: track['im:image'][2].label
              tracks_hash.push(track_hash)

          @_cachedTopTracks = tracks
          success? @_cachedTopTracks

  @history: (success) ->
    History.getTracks((tracks) ->
      success? tracks
    )

  @playlist: (playlist, success) ->
    Playlists.getTracksForPlaylist(playlist, ((tracks) ->
      success? tracks
    ))
