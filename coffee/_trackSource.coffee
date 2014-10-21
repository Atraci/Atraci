# global Requestor, History, Playlists

class TrackSource
  @_defaultImageCover: 'images/cover_default_large.png'
  @search: (options, success) ->
    self = @
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

    if options.type is 'default'
      # itunes
      Requestor.get
        url:
          'http://itunes.apple.com/search?media=music' +
          '&entity=song&limit=100&term=' + encodeURIComponent(options.keywords)
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
      Requestor.get
        url:
          'http://ws.audioscrobbler.com/2.0/?method=track.search' +
          '&api_key=c513f3a2a2dad1d1a07021e181df1b1f&format=json&track=' +
          encodeURIComponent(options.keywords)
        json: true
      , (error, response, data) ->
        if not error and response.statusCode is 200
          tracks = []
          try
            if data.results.trackmatches.track.name
              data.results.trackmatches.track =
                [data.results.trackmatches.track]

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
      Requestor.get
        url:
          'https://api.soundcloud.com/tracks.json?' +
          'client_id=dead160b6295b98e4078ea51d07d4ed2&q=' +
          encodeURIComponent(options.keywords)
        json: true
      , (error, response, data) ->
        tracks = []
        if error
          alertify.error('Connectivity Error : (' + error + ')')
        else
          $.each data, (i, track) ->
            if track
              console.log track
              trackNameExploded = track.title.split(" - ")
              coverPhoto = track.artwork_url || self._defaultImageCover
              tracks.push
                title: trackNameExploded[0]
                artist: trackNameExploded[1]
                cover_url_medium: coverPhoto
                cover_url_large: coverPhoto

          tracks_all['soundcloud'] = tracks
          if Object.keys(tracks_all).length > 1
            mashTracks()
    else
      Requestor.get
        url:
          'http://gdata.youtube.com/feeds/api/videos/' +
          options.link + '/related?alt=json'
        json: true
      , (error, response, data) ->
        tracks = []
        if not error and response.statusCode is 200
          $.each(data.feed.entry, (i, track) ->
            if !track['media$group']['media$thumbnail']
              coverImageMedium = coverImageLarge = self._defaultImageCover
            else
              coverImageMedium = track['media$group']['media$thumbnail'][1].url
              coverImageLarge = track['media$group']['media$thumbnail'][0].url
            tracks.push
              title: track['media$group']['media$title']['$t']
              artist: track['author'][0]['name']['$t']
              cover_url_medium: coverImageMedium
              cover_url_large: coverImageLarge
          )
        #null the rest so we can add recommendations above
        tracks_all = {
          "itunes": []
          "lastfm": []
          "soundcloud": []
        }
        tracks_all['itunes'] = tracks
        if Object.keys(tracks_all).length > 1
          mashTracks()

  #Recommendation / Suggested Songs
  @recommendations: (artist, title) ->
    if artist and title
      spinner = new Spinner(spinner_opts)
        .spin(playerContainer.find('.cover')[0])
      Requestor.get
        url:
          'http://gdata.youtube.com/feeds/api/videos?alt=json&' +
          'max-results=1&q=' + encodeURIComponent(artist + ' - ' + title)
        json: true,
        (error, response, data) ->
          if not data.feed.entry # no results
            alertify.log l10n.get('not_found')
            console.log l10n.get('not_found')
            spinner.stop()
          else
            $('#SideBar li.active').removeClass('active')
            $('#tracklist-container').empty()
            link =
              data.feed.entry[0].link[0].href.split("v=")[1].split("&")[0]
            TrackSource.search({
              type: 'recommendations',
              link: link
            }, ((tracks) ->
              window.tracklist.populate(tracks)
              spinner.stop()
            ))

  # We will cache feature tracks in this object
  @_cachedPlatformMusic: {}
  @platformMusic: (playlistId, success) ->
    if @_cachedPlatformMusic[playlistId] isnt undefined
      success? @_cachedPlatformMusic[playlistId]
    else
      Requestor.get
        url:
          'http://gdata.youtube.com/feeds/api/playlists/' + playlistId +
          '?start-index=1&amp;max-results=25&amp;v=2&alt=json'
        json: true
      , (error, response, data) =>
        tracks = []
        if not error and response.statusCode is 200
          $.each(data.feed.entry, (i, track) ->
            if !track['media$group']['media$thumbnail']
              coverImageMedium = coverImageLarge = self._defaultImageCover
            else
              coverImageMedium = track['media$group']['media$thumbnail'][1].url
              coverImageLarge = track['media$group']['media$thumbnail'][0].url
            tracks.push
              title: track['media$group']['media$title']['$t']
              artist: track['author'][0]['name']['$t']
              cover_url_medium: coverImageMedium
              cover_url_large: coverImageLarge
          )
        @_cachedPlatformMusic[playlistId] = tracks
        success? @_cachedPlatformMusic[playlistId]

  @_cachedFeaturedArtist: {}
  @featuredArtist: (success) ->
    # XXX : we would support multiple artists in the future
    if @_cachedFeaturedArtist['default'] isnt undefined
      success? @_cachedFeaturedArtist['default']
    else
      # XXX: Let's use rawgit's cdn version later if stable
      Requestor.get
        url: 'https://rawgit.com/Atraci/Atraci/master/featured.json'
        json: true
      , (error, response, data) =>
        if not error and response.statusCode is 200
          @_cachedFeaturedArtist['default'] = data
          success? @_cachedFeaturedArtist['default']

  # We will cache feature tracks in this array
  @_cachedTopTracks: []
  @topTracks: (success) ->
    if @_cachedTopTracks.length > 0
      success? @_cachedTopTracks
    else
      Requestor.get
        url:'http://itunes.apple.com/rss/topsongs/limit=100/explicit=true/json'
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
