fs = require('fs')

class PlaylistPanel
  constructor: ->

    initDialog: ->
    # Selectors
    @playlistPanel = $('#playlist-panel')
    @playlistPopup = $('.new')
    @playlistName = $('#playListName')
    @positionTarget = $('body')
    @playlistPanel.keydown((e) ->
      if e.keyCode is $.ui.keyCode.ENTER
        saveButton = $(@).parent().find('.ui-dialog-buttonpane button:last')
        saveButton.click()
    )
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
                    Utils.createRandomPlaylistName(youtubePlaylistId)
                  Playlists.create(playlistName, youtubePlaylistId, ->
                    Playlists.getAll((playlists) ->
                      sidebar.populatePlaylists(playlists)
                    )
                    userTracking.event('Playlist', 'Create',
                      youtubePlaylistId).send()
                  )
                else
                  playlistName = Utils.filterSymbols(str)
                  Playlists.create(playlistName, '', ->
                    Playlists.getAll((playlists) ->
                      sidebar.populatePlaylists(playlists)
                    )
                    userTracking.event(
                      "Playlist", "Create", playlistName).send()
                  )
                $('#playListName').val("")

                # Animate new playlist add effect
                # Find newly created playlist
                setTimeout( ->
                  
                  newPlaylist = $(".drop-area__item").find(
                    ":contains('" + playlistName + "')"
                  ).parent()
                  
                  console.log $(newPlaylist).offset().top
                  
                  $("#drop-area").addClass("show")

                  setTimeout( ->
                    $("#drop-area").animate(
                      { scrollTop:  ($(newPlaylist).offset().top - 80) }
                    , 800)
                    $( newPlaylist ).effect( "slide", {}, 1000)
                    setTimeout( ->
                      $("#drop-area").removeClass("show")
                      setTimeout( ->
                        $("#drop-area").animate(
                          { scrollTop:  0 }
                        , 0)
                      ,200)
                    , 2500)

                  , 500)
                , 200)
                

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
  @clear = (success) ->
    db.playlist.remove({}, { multi: true }, (error) ->
      if error
        console.log("Playlists.clear remove playlist erorr :")
        console.log(error)
        success?()
      else
        db.track.remove({}, { multi: true }, (error) ->
          if error
            console.log("Playlists.clear remove track erorr :")
            console.log(error)
            success?()
          else
            success?()
        )
    )

  @addTrack: (artist, title, cover_url_medium, cover_url_large, playlist) ->
    unix_timestamp = Math.round((new Date()).getTime() / 1000)

    db.track.remove({
      artist: artist,
      title: title,
      playlist: playlist
    }, {}, (error) ->
      if error
        console.log("Playlists.addTrack remove track erorr :")
        console.log(error)
      else
        db.track.insert({
          artist: artist,
          title: title,
          cover_url_medium: cover_url_medium,
          cover_url_large: cover_url_large,
          playlist: playlist,
          added: unix_timestamp
        }, (error) ->
          if error
            console.log("Playlists.addTrack insert track erorr :")
            console.log(error)
        )
    )

  @updatePlaylistPos: (playlistName, position) ->
    db.playlist.update({
      name: playlistName
    }, {
      $set: {
        position: position
      }
    }, {}, (error) ->
      if error
        console.log("Playlists.updatePlaylistPos update playlist erorr :")
        console.log(error)
    )

  @removeTrack: (artist, title, playlist) ->
    db.track.remove({
      artist: artist,
      title: title,
      playlist: playlist
    }, {}, (error) ->
      if error
        console.log("Playlists.removeTrack remove track erorr :")
        console.log(error)
    )

  @create: (name, platform_id = '', success) ->
    unix_timestamp = Math.round((new Date()).getTime() / 1000)
    db.playlist.remove({
      name: name
    }, {}, (error) ->
      if error
        console.log("Playlists.create remove playlist erorr :")
        console.log(error)
      else
        db.playlist.insert({
          name: name,
          platform_id: platform_id,
          created: unix_timestamp,
          position: 0
        }, (error) ->
          if error
            console.log("Playlists.create create playlist erorr :")
            console.log(error)
          else
            success?()
        )
    )

  @delete: (name) ->
    db.playlist.remove({
      name: name
    }, {}, (error) ->
      if error
        console.log("Playlists.delete remove playlist erorr :")
        console.log(error)
      else
        db.track.remove({
          playlist: name
        }, {}, (error) ->
          if error
            console.log("Playlists.delete remove track erorr :")
            console.log(error)
        )
    )

  @export: (name) ->
    exportDump = []
    #Insert Signature to identify playlist files
    exportDump.push('Atraci:ImportedPlaylist:' + name)

    db.track.find({
      playlist: name
    }, (error, foundTracks) ->
      if error
        console.log("Playlists.export find track erorr :")
        console.log(error)
      else
        i = 0

        while i < foundTracks.length
          exportDump.push(foundTracks[i])
          i++

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
    db.playlist.find({}).sort({
      position: 1
    }).exec((error, foundPlaylists) ->
      if error
        console.log("Playlists.getAll find playlist erorr :")
        console.log(error)
        success?([])
      else
        __playlists = foundPlaylists
        success?(foundPlaylists)
    )

  @getTracksForPlaylist = (playlist, success) ->
    db.track.find({
      playlist: playlist
    }).sort({
      added: 1
    }).exec((error, foundTracks) ->
      if error
        console.log("Playlists.getTracksForPlaylist find track erorr :")
        console.log(error)
        success?([])
      else
        success?(foundTracks)
    )

  @getPlaylistNameExist: (name, success) ->
    db.playlist.find({
      name: name
    }, (error, foundPlaylists) ->
      if error
        console.log("Playlists.getPlaylistNameExist find playlist erorr :")
        console.log(error)
        success?(0)
      else
        success?(foundPlaylists.length)
    )

  @rename: (name, new_name) ->
    db.playlist.update({
      name: name
    }, {
      $set: {
        name: new_name
      }
    }, {}, (error) ->
      if error
        console.log("Playlists.rename update playlist erorr :")
        console.log(error)
      else
        Playlists.getTracksForPlaylist(name, ((tracks) ->
          i = 0
          while i < tracks.length
            Playlists.addTrack(
              tracks[i].artist, tracks[i].title, tracks[i].cover_url_medium,
              tracks[i].cover_url_large, new_name)
            i++
        ))

        Playlists.delete(name)
    )
