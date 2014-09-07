# Init preparation (should be improved later)
db.transaction (tx) ->
  tx.executeSql(
    'CREATE TABLE IF NOT EXISTS playlists' +
    '(name, platform_id, created, position)'
  )

  tx.executeSql(
    'ALTER TABLE playlists ADD platform_id DEFAULT ""'
  )

  tx.executeSql(
    'ALTER TABLE playlists ADD position DEFAULT 1'
  )

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
      tx.executeSql(
        'CREATE TABLE IF NOT EXISTS playlist_tracks ' +
        '(artist, title, cover_url_medium, cover_url_large, playlist, added)'
      )
      tx.executeSql(
        'DELETE FROM playlist_tracks WHERE ' +
        'artist = ? and title = ? and playlist = ?',
        [artist, title, playlist]
      )
      tx.executeSql(
        'INSERT INTO playlist_tracks ' +
        '(artist, title, cover_url_medium, cover_url_large, playlist, added) '+
        'VALUES (?, ?, ?, ?, ?, ?)',
        [artist, title, cover_url_medium, cover_url_large,
        playlist, unix_timestamp]
      )

  @updatePlaylistPos: (playlistName, position) ->
    db.transaction (tx) ->
      tx.executeSql(
        'update playlists set ' +
        'position = ? WHERE name = ?', [position, playlistName]
      )

  @removeTrack: (artist, title, playlist) ->
    db.transaction (tx) ->
      tx.executeSql(
        'DELETE FROM playlist_tracks WHERE ' +
        'artist = ? and title = ? and playlist = ?', [artist, title, playlist]
      )

  @create: (name, platform_id = '') ->
    unix_timestamp = Math.round((new Date()).getTime() / 1000)
    db.transaction (tx) ->
      tx.executeSql 'DELETE FROM playlists WHERE name = ?', [name]
      tx.executeSql(
        'INSERT INTO playlists (name, platform_id, created, position)' +
        'VALUES (?, ?, ?, 0)',
        [name, platform_id, unix_timestamp]
      )

  @delete: (name) ->
    db.transaction (tx) ->
      tx.executeSql 'DELETE FROM playlists WHERE name = ?', [name]
      tx.executeSql 'DELETE FROM playlist_tracks WHERE playlist = ?', [name]

  @getAll = (success) ->
    playlists = []
    db.transaction (tx) ->
      tx.executeSql(
        'SELECT * FROM playlists ORDER BY position ASC', [], (tx, results) ->
          i = 0
          while i < results.rows.length
            playlists.push results.rows.item(i)
            i++
          __playlists = playlists
          success? playlists
      )
        
  @getTracksForPlaylist = (playlist, success) ->
    tracks = []
    db.transaction (tx) ->
      tx.executeSql(
        'SELECT * FROM playlist_tracks WHERE playlist = ? ORDER BY added ASC',
        [playlist], (tx, results) ->
          i = 0
          while i < results.rows.length
            tracks.push results.rows.item(i)
            i++
          success? tracks
      )

  @rename: (name, new_name) ->
    db.transaction((tx) ->
      tx.executeSql(
        'UPDATE playlists SET name = ? WHERE name = ?', [new_name, name]
      )
    )

    Playlists.getTracksForPlaylist(name, ((tracks) ->
      i = 0
      while i < tracks.length
        Playlists.addTrack(
          tracks[i].artist, tracks[i].title, tracks[i].cover_url_medium,
          tracks[i].cover_url_large, new_name)
        i++
    ))

    Playlists.delete(name)
