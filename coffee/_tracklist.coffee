# global TrackSource, l10n, Playlists, TrackSource, userTracking, jQuery
class Tracklist
  constructor: ->
    @_currentTracklist = []
    @_contentWrapper = $('#ContentWrapper')
    @_artistPageTemplate = $('#tmpl-artistPage')
    @_tracklistTemplate = $('#tmpl-tracklist')
    @_tracklistErrorTemplate = $('#tmpl-tracklist-error')
    @_tracklistSorter = $('#tracklistSorter')
    @_trackContainerClass = '.track-container'

    @bindEvents()

  bindEvents: ->
    self = @

    @_contentWrapper.on 'contextmenu', @_trackContainerClass, (e) ->
      currentTrackContainer = $(@)

      # this is an option used to create menuItem if needed
      options =
        playlistName: ''
        artist: $(@).find('.artist').text()
        title: $(@).find('.title').text()
        coverMediumURL: $(@).find('.cover').attr('data-cover_url_medium')
        coverLargURL: $(@).find('.cover').attr('data-cover_url_large')

      e.stopPropagation()
      menu = new gui.Menu()

      Playlists.getAll((playlists) ->
        # create playlists
        $.each playlists, (index, playlist) ->

          # Do nothing if we are in active playlist
          if playlist.name is self._getActivePlaylistName()
            return

          options.playlistName = playlist.name
          menu.append self._createPlaylistMenuItem(options)

        if self._isActivePlaylist()
          options.playlistName = self._getActivePlaylistName()
          menu.append self._createRemoveFromPlaylistMenuItem(
            currentTrackContainer, options)

        # Add one more separator to make it look sexy
        if playlists.length isnt 0
          menu.append self._createSeparatorMenuItem()

        menu.append self._createOpenYoutubeMenuItem(options)
        menu.append self._createFindMoreMenuItem(options)

        # show menu
        menu.popup e.clientX, e.clientY
      )

  getCurrentTracklist: ->
    return @_currentTracklist

  # XXX refactor this ...
  populate: (tracks, artistObject, fromSort) ->
    @_currentTracklist = []

    if tracks.length > 0 && !fromSort
      for x of tracks
        tracks[x].id = x

    tracks = @_sortTracklist tracks

    @_contentWrapper
      .empty()
      .scrollTop()

    # XXX access this from sideBar class later
    if artistObject && $('#SideBar .active').hasClass('featured-artist')
      @_artistPageTemplate
        .tmpl(artistObject)
        .prependTo(@_contentWrapper)

    if tracks.length > 0
      @_tracklistTemplate
        .tmpl(tracks)
        .appendTo(@_contentWrapper)
      @_currentTracklist = tracks
      @calculateDivsInRow()
    else
      @_tracklistErrorTemplate
        .tmpl({message: 'No tracks'})
        .appendTo(@_contentWrapper)

  getSelectedSortBy: ->
    return @_tracklistSorter.find(':selected').attr('value')

  # XXX refactor this ...
  _sortTracklist: (tracks) ->
    tmpTracks = []
    switch @getSelectedSortBy()
      when 'SongsName'
        tmpTracks = tracks.sort (a, b) ->
          a.title.localeCompare(b.title)

      when 'ArtistName'
        tmpTracks = tracks.sort (a, b) ->
          a.artist.localeCompare(b.artist)

      when 'Default'
        for y in tracks
          tmpTracks[y.id] = y

    tmpTracks

  # XXX refactor this later
  calculateDivsInRow: ->
    $('.ghost').remove()
    divsInRow = 0

    @_contentWrapper.find(@_trackContainerClass).each ->
      if $(@).prev().length > 0
        if $(@).position().top isnt $(@).prev().position().top
          return false
        divsInRow++
      else
        divsInRow++
      return

    divsInLastRow = @_contentWrapper.find(
      @_trackContainerClass).length % divsInRow

    if divsInLastRow is 0
      divsInLastRow = divsInRow

    to_add = divsInRow - divsInLastRow

    while to_add > 0
      @_contentWrapper.append $('<div/>').addClass('track-container ghost')
      to_add--
    return

  # XXX refactor tihs to playlist object
  _isActivePlaylist: ->
    return $('#SideBar li.active').hasClass('playlist')

  # XXX refactor tihs to playlist object
  _getActivePlaylistName: ->
    return $('#SideBar li.active').text()

  _createSeparatorMenuItem: () ->
    return new gui.MenuItem(type: 'separator')

  _createPlaylistMenuItem: (options) ->
    playlistName = options.playlistName
    artist = options.artist
    title = options.title
    coverMediumURL = options.coverMediumURL
    coverLargURL = options.coverLargURL

    return new gui.MenuItem(
      label: 'Add to ' + playlistName,
      click: ->
        Playlists.addTrack(
          artist,
          title,
          coverMediumURL,
          coverLargURL,
          playlistName
        )
        userTracking.event(
          'Playlist',
          'Add Track to Playlist',
          playlistName
        ).send()
    )

  _createRemoveFromPlaylistMenuItem: (currentTrackContainer, options) ->
    playlistName = options.playlistName
    artist = options.artist
    title = options.title

    return new gui.MenuItem(
      label: 'Remove from ' + playlistName,
      click: ->
        Playlists.removeTrack(
          artist,
          title,
          playlistName
        )
        currentTrackContainer.remove()
        userTracking.event(
          'Playlist',
          'Remove Track to Playlist',
          playlistName
        ).send()
    )

  _createOpenYoutubeMenuItem: (options) ->
    artist = options.artist
    title = options.title
    return new gui.MenuItem(
      label: l10n.get('open_youtube'),
      click: ->
        request
          url:
            'http://gdata.youtube.com/feeds/api/videos?alt=json&' +
            'max-results=1&q=' + encodeURIComponent(artist + ' - ' + title)
          json: true,
          (error, response, data) ->
            if not data.feed.entry # no results
              alertify.log l10n.get('link_not_found')
              console.log l10n.get('link_not_found')
            else
              link = data.feed.entry[0].link[0].href
              gui.Shell.openExternal(link)
    )

  _createFindMoreMenuItem: (options) ->
    return new gui.MenuItem(
      label: l10n.get('find_more'),
      click: ->
        TrackSource.recommendations(options.artist, options.title)
    )
