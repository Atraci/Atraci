fs = require('fs')

class PlaylistPanel
  constructor: ->

    initDialog: ->
    # Selectors
    @playlistPanel = $('#playlist-panel')
    @playlistPopup = $('.new')
    @playlistName = $('#playListName')
    @positionTarget = $('body')


    @playlistPanel.dialog
      autoOpen: false,
      height: 220,
      width: 350,
      position:
        of: @positionTarget
      show:
        effect: 'blind',
        duration: 500
      hide:
        effect: 'blind',
        duration: 500
      title: 'Add New Playlist',
      modal: true,
      dialogClass: 'settingsClass',
      buttons: [
        text: 'Cancel',
        click: =>
          @close()
      ,
        text: 'Import',
        click: =>
          $('#fileinput').trigger('click')
          @close()
      ,
        text: 'Save',
        click: =>
          str = @playlistName.val()
          if str.length < 1
            return
          else
            Playlists.getPlaylistNameExist(str, (length) ->
              if !length
                youtubePlaylistId = Utils.getYoutubePlaylistId(str)
                # We can support other platform's video here
                if youtubePlaylistId
                  playlistName =
                    l10n.get('playlist') + '-' + youtubePlaylistId.substr(0, 5)
                  Playlists.create(playlistName, youtubePlaylistId)
                  Playlists.getAll((playlists) ->
                    sidebar.populatePlaylists(playlists)
                  )
                  userTracking.event('Playlist', 'Create',
                    youtubePlaylistId).send()
                else
                  playlistName = Utils.filterSymbols(str)
                  Playlists.create(playlistName)
                  Playlists.getAll((playlists) ->
                    sidebar.populatePlaylists(playlists)
                  )
                  userTracking.event("Playlist", "Create", playlistName).send()
                $('#playListName').val("")
              else
                alertify.alert("This playlist name already exists")
            )
            @close()
      ]

  close: ->
    @playlistPanel.dialog 'close'

  show:  ->
    @playlistPanel.dialog 'open'

  reposition: ->
    @playlistPanel.dialog('option', 'position',
      of: @positionTarget
    )

  $('#fileinput').on 'change', ->
    Playlists.import($('#fileinput').val())
    $('#fileinput').val("")

  bindEvents: ->
    @playlistPopup.on 'click', =>
      if @playlistPanel.is ':hidden'
        @show()
      else
        @close()


__playlists = []

class Playlists

  @initDB: ->
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

  @export: (name) ->
    exportDump = []
    #Insert Signature to identify playlist files
    exportDump.push "Atraci:ImportedPlaylist:"+name
    db.transaction (tx) ->
      tx.executeSql(
        'SELECT * FROM playlist_tracks WHERE playlist = ?',
        [name], (tx, results) ->
          i = 0
          while i < results.rows.length
            exportDump.push results.rows.item(i)
            i++
          success? exportDump
          fs.writeFile name + "Playlist.atpl",
          JSON.stringify(exportDump), (error) ->
            console.error("Error writing file", error) if error
          alertify.log "Exported " + name + "Playlist.json" +
          " to: " + process.cwd()
      )

  @import: (name) ->
    objects = []
    if name.split(".")[1] is not "atpl"
      alertify.error "Not an Atraci Playlist File"
      return
    #Read file and build structure that can be inserted via SQL to playlist DB
    fs.readFile name, (error, data) ->
      if error
        alertify.error error
        return
      else
        try
          objects = $.parseJSON data
          signature = objects[0].split(":")
        catch e
          alertify.error "Not an Atraci Playlist File."
          console.log e
          return
        #Verify Signature for playlist first
        if signature[0] is "Atraci" and signature[1] is "ImportedPlaylist"
          try
            Playlists.create(signature[2])
            Playlists.addTrack(track['artist'],
            track['title'],
            track['cover_url_medium'],
            track['cover_url_large'],
            track['playlist']) for track in objects
            Playlists.getAll((playlists) ->
              sidebar.populatePlaylists(playlists)
            )
            alertify.log "Playlist " + signature[2] + " imported."
          catch e
            alertify.error "Playlist file " + name + " seems corrupt."
            console.log e
            return

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

  @getPlaylistNameExist: (name, callback) ->
    db.transaction((tx) ->
      tx.executeSql(
        'SELECT name FROM playlists WHERE name = ?',
        [name], (tx, results) ->
          callback(results.rows.length)
      )
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
