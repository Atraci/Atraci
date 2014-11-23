# global User, TrackSource, jQuery, tracklist
class Sidebar
  constructor: ->
    @sidebarContainer = $('#SideBar')
    @contentWrapper = $('#ContentWrapper')
    @_playlistTemplate = $('#tmpl-playlist')
    @_playlistAreaList = $('#drop-area-list')
    @topSidebar = @sidebarContainer.find('.top-sidebar ul')
    @middleSidebar = @sidebarContainer.find('.middle-sidebar ul')
    @bottomSidebar = @sidebarContainer.find('.bottom-sidebar ul')

    @bindEvents()

  bindEvents: ->
    self = @
    activeableList = [
      'li.history',
      'li.playlist',
      'li.top',
      'li.featured-artist',
      'li.featured-music',
      'li.playlist'
    ]

    @sidebarContainer.on('click', activeableList.join(','), ->
      self.sidebarContainer.find('.active').removeClass('active')
      $(@).addClass('active')
    )

    @sidebarContainer.on('click', 'li', ->
      if !$(@).hasClass('no-page')
        self.contentWrapper.empty()
        spinner = new Spinner(spinner_opts).spin(self.contentWrapper[0])

      # This should be put at the top
      # because featured-music and playlist with data-id would
      # render songs from online platforms
      if $(@).data('id')
        TrackSource.platformMusic($(@).data('id'), (tracks) ->
          spinner.stop()
          window.tracklist.populate(tracks)
        )
      else if $(@).hasClass('top')
        TrackSource.topTracks((tracks) ->
          spinner.stop()
          window.tracklist.populate(tracks)
        )
      else if $(@).hasClass('history')
        TrackSource.history((tracks) ->
          spinner.stop()
          window.tracklist.populate(tracks)
        )
      else if $(@).hasClass('playlist')
        TrackSource.playlist($(@).data('name'), ((tracks) ->
          spinner.stop()
          window.tracklist.populate(tracks)
        ))
      else if $(@).hasClass('featured-artist')
        TrackSource.featuredArtist((artist)->
          doSearch artist.value, true, (tracks) ->
            window.tracklist.populate(tracks, artist)
            spinner.stop()
        )
      else if $(@).hasClass('settings')
        if $('#settings-panel').is ':hidden'
          settingsPanel.show()
        else
          settingsPanel.close()
      else if $(@).hasClass('donations')
        gui.Shell.openExternal(
          'https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&' +
          'hosted_button_id=Q9SDPBK7VMQ8N'
        )
    )

    @bottomSidebar.on 'click', 'li.new', ->
      playlistPanel.show()

    @bottomSidebar.on 'contextmenu', 'li.playlist', (e) ->
      e.stopPropagation()
      playlistName = Utils.filterSymbols($(@).data('name'))
      menu = new gui.Menu()
      menu.append self._createDeleteMenuItem(playlistName)
      menu.append self._createRenameMenuItem(playlistName)
      menu.append self._createExportMenuItem(playlistName)
      menu.popup e.clientX, e.clientY

  getActiveItem: ->
    return @sidebarContainer.find('ul li.active')

  getActivePlaylistName: ->
    activeItem = @getActiveItem()
    if activeItem.hasClass('playlist')
      return activeItem.text()
    else
      return ''

  populateFeaturedMusic: ->
    self = @
    # We will lazily append featured-music into sidebar
    User.getInfo((userInfo) ->
      country = userInfo.country
      $.getJSON('featured-music/' + country + '.json').done((data) ->
        playlists = data.playlists
        $.each playlists, (index, playlist) ->
          # We have to insert them below 'featured Artist'
          self.topSidebar.append(self._createFeaturedMusicItem(
            id: playlist.id
            name: playlist.name
          ))
      ).fail(->
        console.log 'failed to fetch ' + country + '.json'
      )
    )

  # Not the place for this function
  # Placing it here till another can be found
  getRandomColor = ->
    letters = "012345".split("")
    color = "#"
    color += letters[Math.round(Math.random() * 5)]
    letters = "0123456789ABCDEF".split("")
    i = 0

    while i < 5
      color += letters[Math.round(Math.random() * 15)]
      i++
    return color

  populatePlaylists: (playlists) ->
    self = @
    @bottomSidebar.find('li.playlist').remove()
    @_playlistAreaList.find('.drop-playlist').remove()

    for playlist in playlists
      @bottomSidebar.append(
        @_createPlaylistItem(playlist.name, playlist.platform_id)
      )

    # Add playlist name to playlist template
    playlistAreaList = []
    for playlist in playlists
      playlistAreaList.push(
        'name': playlist.name,
        'letter': playlist.name.charAt(0).toUpperCase(),
        'platform_id': playlist.platform_id,
        'bgColor': getRandomColor()
      )
    @_playlistTemplate
      .tmpl({playlistAreaList})
      .appendTo(@_playlistAreaList)
    window.tracklist.makeDraggable()

    # Re-active context after repopulating
    @_reactivePlaylistItem(@getActivePlaylistName())
    @bottomSidebar.sortable({
      placeholder: "ui-state-highlight",
      items: "li:not(.new)",
      update: (event, ui) ->
        self._updatePlaylistPos()
    })

  _updatePlaylistPos: () ->
    sideBarItems = @bottomSidebar.find("li:not(.new)")

    sideBarItems.each () ->
      Playlists.updatePlaylistPos($(@).attr("data-name"), $(@).index())


  _createPlaylistItem: (playlistName, platformId) ->
    if platformId
      # if this is youtube playlist or some other platforms' platlist
      playlistItem = $("""
        <li class='playlist' data-name='#{playlistName}'
          data-id='#{platformId}'>
            <i class='fa fa-youtube'></i>
            <i class='fa fa-align-justify'></i>
            <span>#{playlistName}</span>
        </li>
      """)
    else
      playlistItem = $("
        <li class='playlist' data-name='#{playlistName}'>
            <i class='fa fa-align-justify'></i>
                #{playlistName}
        </li>
      ")

    return playlistItem

  _reactivePlaylistItem: (activePlaylistName) ->
    @sidebarContainer.find('ul li').filter( ->
      $(@).text() == activePlaylistName
    ).addClass('active')

  _createFeaturedMusicItem: (options) ->
    playlistId = options.id
    playlistName = options.name

    return $("
      <li class='featured-music' data-id='#{playlistId}'>
        <i class='fa fa-music'></i>
        <span>#{playlistName}</span>
      </li>
    ")

  _createDeleteMenuItem: (playlistName) ->
    self = @
    return new gui.MenuItem(
      label: 'Delete ' + playlistName,
      click: ->
        alertify.confirm l10n.get('delete_playlist_popup'), (e) ->
          if e
            self.sidebarContainer.find(
              '[data-name="' + playlistName + '"]').remove()
            Playlists.delete(playlistName)
            Playlists.getAll((playlists) ->
              self.populatePlaylists(playlists)
            )
            userTracking.event("Playlist", "Delete", playlistName).send()
    )

  _createExportMenuItem: (playlistName) ->
    self = @
    return new gui.MenuItem(
      label: 'Export ' + playlistName,
      click: ->
        Playlists.export(playlistName)
        userTracking.event("Playlist", "Exported", playlistName).send()
    )

  _createRenameMenuItem: (oldPlaylistName) ->
    self = @
    return new gui.MenuItem(
      label: 'Rename ' + $(@).text(),
      click: ->
        alertify.prompt l10n.get('rename_playlist_popup'), (e, newName) ->
          if e && newName
            newName = Utils.filterSymbols(newName)
            Playlists.getPlaylistNameExist(newName, (length) ->
              if !length
                Playlists.rename(oldPlaylistName, newName)
                Playlists.getAll((playlists) ->
                  self.populatePlaylists(playlists)
                )
                userTracking.event("Playlist", "Rename", newName).send()
              else
                alertify.alert("This playlist name already exists")
            )
          else
            return
        , oldPlaylistName
    )
