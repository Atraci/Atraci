# Init preparation (should be improved later)
db.transaction (tx) ->
    tx.executeSql 'CREATE TABLE IF NOT EXISTS playlists (name, created)'

__playlists = []

class Playlists

    @clear = (success) ->
        db.transaction (tx) ->
            tx.executeSql 'DROP TABLE playlist_tracks'
            tx.executeSql 'DROP TABLE playlists'
            success?()

    @addTrack: (artist, title, cover_url_medium, cover_url_large, playlist) ->
        unix_timestamp = Math.round((new Date()).getTime() / 1000)
        db.transaction (tx) ->
            tx.executeSql 'CREATE TABLE IF NOT EXISTS playlist_tracks (artist, title, cover_url_medium, cover_url_large, playlist, added)'
            tx.executeSql 'DELETE FROM playlist_tracks WHERE artist = ? and title = ? and playlist = ?', [artist, title, playlist]
            tx.executeSql 'INSERT INTO playlist_tracks (artist, title, cover_url_medium, cover_url_large, playlist, added) VALUES (?, ?, ?, ?, ?, ?)', [artist, title, cover_url_medium, cover_url_large, playlist, unix_timestamp]

    @removeTrack: (artist, title, playlist) ->
        db.transaction (tx) ->
            tx.executeSql 'DELETE FROM playlist_tracks WHERE artist = ? and title = ? and playlist = ?', [artist, title, playlist]

    @create: (name) ->
        unix_timestamp = Math.round((new Date()).getTime() / 1000)
        db.transaction (tx) ->
            tx.executeSql 'DELETE FROM playlists WHERE name = ?', [name]
            tx.executeSql 'INSERT INTO playlists (name, created) VALUES (?, ?)', [name, unix_timestamp]

    @delete: (name) ->
        db.transaction (tx) ->
            tx.executeSql 'DELETE FROM playlists WHERE name = ?', [name]
            tx.executeSql 'DELETE FROM playlist_tracks WHERE playlist = ?', [name]

    @getAll = (success) ->
        playlists = []
        db.transaction (tx) ->
            tx.executeSql 'SELECT * FROM playlists ORDER BY created ASC', [], (tx, results) ->
                i = 0
                while i < results.rows.length
                    playlists.push results.rows.item(i)
                    i++
                __playlists = playlists
                success? playlists

    @getTracksForPlaylist = (playlist, success) ->
        tracks = []
        db.transaction (tx) ->
            tx.executeSql 'SELECT * FROM playlist_tracks WHERE playlist = ? ORDER BY added DESC', [playlist], (tx, results) ->
                i = 0
                while i < results.rows.length
                    tracks.push results.rows.item(i)
                    i++
                success? tracks

    @rename: (name, new_name) ->
        db.transaction (tx) ->
            tx.executeSql 'UPDATE playlists SET name = ? WHERE name = ?', [new_name, name]
