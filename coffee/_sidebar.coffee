# global User, TrackSource, jQuery, tracklist
class Sidebar
  constructor: ->
    @sidebarContainer = $('#SideBar')
    @contentWrapper = $('#ContentWrapper')
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

      if $(@).hasClass('top')
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
        TrackSource.playlist($(@).text(), ((tracks) ->
          spinner.stop()
          window.tracklist.populate(tracks)
        ))
      else if $(@).hasClass('featured-music')
        TrackSource.featuredMusic($(@).data('id'), (tracks) ->
          spinner.stop()
          window.tracklist.populate(tracks)
        )
      else if $(@).hasClass('featured-artist')
        self._loadFeaturedArtistPage( ->
          spinner.stop()
        )
      else if $(@).hasClass('donations')
        gui.Shell.openExternal(
          'https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&' +
          'hosted_button_id=Q9SDPBK7VMQ8N'
        )
    )

    @bottomSidebar.on 'click', 'li.new', ->
      alertify.prompt l10n.get('create_playlist_popup'), (e, str) ->
        if !e or !str
          return
        else
          Playlists.create(str)
          Playlists.getAll((playlists) ->
            self.populatePlaylists(playlists)
          )
          userTracking.event("Playlist", "Create", str).send()

    @bottomSidebar.on 'contextmenu', 'li.playlist', (e) ->
      e.stopPropagation()
      playlistName = $(@).text()
      menu = new gui.Menu()
      menu.append self._createDeleteMenuItem(playlistName)
      menu.append self._createRenameMenuItem(playlistName)
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

  populatePlaylists: (playlists) ->
    @bottomSidebar.find('li.playlist').remove()

    for playlist in playlists
      @bottomSidebar.append(
        @_createPlaylistItem(playlist.name)
      )

    # Re-active context after repopulating
    @_reactivePlaylistItem(@getActivePlaylistName())

  _createPlaylistItem: (playlistName) ->
    return $("
      <li class='playlist' data-name='#{playlistName}'>#{playlistName}</li>
    ")

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

  # XXX this should be put to another class
  _loadFeaturedArtistPage: (callback) ->
    $.getJSON("http://getatraci.net/featured.json", (artistObject) ->
      doSearch artistObject.value, true, (tracks) ->
        window.tracklist.populate(tracks, artistObject)
        callback()
    )

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

  _createRenameMenuItem: (oldPlaylistName) ->
    self = @
    return new gui.MenuItem(
      label: 'Rename ' + $(@).text(),
      click: ->
        alertify.prompt l10n.get('rename_playlist_popup'), (e, str) ->
          if e && str
            Playlists.rename(oldPlaylistName, str)
            Playlists.getAll((playlists) ->
              self.populatePlaylists(playlists)
            )
            userTracking.event("Playlist", "Rename", str).send()
          else
            return
        , oldPlaylistName
    )
