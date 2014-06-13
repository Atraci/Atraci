request = require('request')

class TrackSource

    @search: (keywords, success) ->
        tracks_all = {}

        mashTracks = ->
            tracks_all = tracks_all['itunes'].concat tracks_all['lastfm']
            
            tracks_deduplicated = []
            tracks_hash = []
            $.each tracks_all, (i, track) ->
                if track.artist and track.title
                    track_hash = track.artist.toLowerCase() + '___' + track.title.toLowerCase()
                    if track_hash not in tracks_hash
                        tracks_deduplicated.push(track)
                        tracks_hash.push(track_hash)
            success? tracks_deduplicated

        # itunes
        request
            url: 'http://itunes.apple.com/search?media=music&entity=song&limit=100&term=' + encodeURIComponent(keywords)
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
                if Object.keys(tracks_all).length == 2
                    mashTracks()

        # last.fm
        request
            url: 'http://ws.audioscrobbler.com/2.0/?method=track.search&api_key=c513f3a2a2dad1d1a07021e181df1b1f&format=json&track=' + encodeURIComponent(keywords)
            json: true
        , (error, response, data) ->
            if not error and response.statusCode is 200
                tracks = []
                try
                    if data.results.trackmatches.track.name
                        data.results.trackmatches.track = [data.results.trackmatches.track]
                    $.each data.results.trackmatches.track, (i, track) ->
                        cover_url_medium = cover_url_large = 'images/cover_default_large.png'
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
                if Object.keys(tracks_all).length == 2
                    mashTracks()


    @topTracks: (success) ->
        request
            url: 'http://itunes.apple.com/rss/topsongs/limit=50/explicit=true/json'
            json: true
        , (error, response, data) ->
            if not error and response.statusCode is 200
                tracks = []
                tracks_hash = []
                $.each data.feed.entry, (i, track) ->
                    track_hash = track['im:artist'].label + '___' + track['im:name'].label
                    if track_hash not in tracks_hash
                        tracks.push
                            title: track['im:name'].label
                            artist: track['im:artist'].label
                            cover_url_medium: track['im:image'][1].label
                            cover_url_large: track['im:image'][2].label
                        tracks_hash.push(track_hash)
                success? tracks

    @history: (success) ->
        History.getTracks((tracks) ->
            success? tracks
        )


    @playlist: (playlist, success) ->
        Playlists.getTracksForPlaylist(playlist, ((tracks) ->
            success? tracks
        ))