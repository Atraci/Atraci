# Init preparation (should be improved later)
db.transaction (tx) ->
    tx.executeSql 'CREATE TABLE IF NOT EXISTS history (artist, title, cover_url_medium, cover_url_large, last_played)'

class History

    @clear: (success) ->
        db.transaction (tx) ->
            tx.executeSql 'DROP TABLE history'
            success?()

    @addTrack: (artist, title, cover_url_medium, cover_url_large) ->
        unix_timestamp = Math.round((new Date()).getTime() / 1000)
        db.transaction (tx) ->
            tx.executeSql 'CREATE TABLE IF NOT EXISTS history (artist, title, cover_url_medium, cover_url_large, last_played)'
            tx.executeSql 'DELETE FROM history WHERE artist = ? and title = ?', [artist, title]
            tx.executeSql 'INSERT INTO history (artist, title, cover_url_medium, cover_url_large, last_played) VALUES (?, ?, ?, ?, ?)', [artist, title, cover_url_medium, cover_url_large, unix_timestamp]

    @getTracks: (success) ->
        tracks = []
        db.transaction (tx) ->
            tx.executeSql 'SELECT * FROM history ORDER BY last_played DESC LIMIT 150', [], (tx, results) ->
                i = 0
                while i < results.rows.length
                    tracks.push results.rows.item(i)
                    i++
                success? tracks

    @countTracks: (success) ->
        db.transaction (tx) ->
            tx.executeSql 'SELECT COUNT(*) AS cnt FROM history', [], (tx, results) ->
                success? results.rows.item(0).cnt