# global TrackSource, l10n, Playlists, TrackSource, userTracking, jQuery,
# sidebar
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

      if window.sidebar.getActiveItem().hasClass('history')
        menu.append self._createRemoveFromHistoryMenuItem(
          currentTrackContainer, options)

      Playlists.getAll((playlists) ->
        # create playlists
        $.each playlists, (index, playlist) ->

          isPlatformPlaylist = playlist.platform_id isnt ''
          isActivePlaylist =
            playlist.name is window.sidebar.getActivePlaylistName()

          # Do nothing
          if isActivePlaylist || isPlatformPlaylist
            return

          options.playlistName = playlist.name

          menu.append self._createPlaylistMenuItem(options)

        if window.sidebar.getActiveItem().hasClass('playlist')
          options.playlistName = window.sidebar.getActivePlaylistName()
          menu.append self._createRemoveFromPlaylistMenuItem(
            currentTrackContainer, options)

        # Add one more separator to make it look sexy
        if playlists.length isnt 0
          menu.append self._createSeparatorMenuItem()

        menu.append self._createOpenYoutubeMenuItem(options)
        menu.append self._createFindMoreMenuItem(options)
        menu.append self._createCopyVideoUrlMenuItem(options)

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
      @makeDraggable()

    else
      @_tracklistErrorTemplate
        .tmpl({message: 'No tracks'})
        .appendTo(@_contentWrapper)


  makeDraggable: ->
    body = document.body
    dropArea = document.getElementById("drop-area")
    droppableArr = []
    dropAreaTimeout = undefined

    # initialize droppables
    [].slice.call(document.querySelectorAll("#drop-area .drop-area__item"))
      .forEach (el) ->
        droppableArr.push new Droppable(el,
          onDrop: (instance, draggableEl) ->

            # show checkmark inside the droppabe element
            classie.add instance.el, "drop-feedback"
            clearTimeout instance.checkmarkTimeout
            instance.checkmarkTimeout = setTimeout(->
              classie.remove instance.el, "drop-feedback"
              return
            , 400)

            playlistName = $(el).find(".playlistTitle").text()
            cover = $(draggableEl).find(".cover")
            Playlists.addTrack(
              $(draggableEl).find(".info .title").text(),
              $(draggableEl).find(".info .artist").text(),
              cover.attr("data-cover_url_medium"),
              cover.attr("data-cover_url_large"),
              playlistName
            )
            userTracking.event(
              'Playlist',
              'Add Track to Playlist',
              playlistName
            ).send()

            # Lets add the element to the playlist

            return
        )
        return

    down = null
    startDrag = null

    $('body').mousedown ->
      down = true
      return
    $('body').mouseup ->
      down = false
      return

    # initialize draggable(s)
    [].slice.call(document.querySelectorAll(".grid__item")).forEach (el) ->
      new Draggable(el, droppableArr,
        scroll: true
        scrollable: "#drop-area"
        scrollSpeed: 40
        scrollSensitivity: 50
        draggabilly:
          containment: document.body

        onStart: ->
          setTimeout(->
            if down
              #first
              startDrag = true
              # add class 'drag-active' to body
              classie.add body, "drag-active"

              # clear timeout: dropAreaTimeout (toggle drop area)
              clearTimeout dropAreaTimeout


              # show dropArea
              # toggle sensitivty to prevent click based trigger drag

              classie.add dropArea, "show"
            else
              return
          , 200)
          return

        onEnd: (wasDropped) ->

          # event.toElement is the element that was responsible
          # for triggering this event. The handle, in case of a draggable.
          if startDrag
            $(event.toElement).one "click", (e) ->
              e.stopImmediatePropagation()
              return

          afterDropFn = ->

            #remove isactive
            $(el).removeClass "is-active"

            # hide dropArea

            setTimeout(->
              startDrag = false
              classie.remove dropArea, "show"
            , 400)

            # remove class 'drag-active' from body
            classie.remove body, "drag-active"
            return

          unless wasDropped
            afterDropFn()
          else

            # after some time hide drop area, remove class 'drag-active'
            clearTimeout dropAreaTimeout
            dropAreaTimeout = setTimeout(afterDropFn, 400)
          return
      )
      return

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

  _createSeparatorMenuItem: () ->
    return new gui.MenuItem(type: 'separator')

  _createPlaylistMenuItem: (options) ->
    playlistName = options.playlistName
    artist = options.artist
    title = options.title
    coverMediumURL = options.coverMediumURL
    coverLargURL = options.coverLargURL

    return new gui.MenuItem(
      label: l10n.get('context_menu_add_to_playlist') + ' ' + playlistName,
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
      label: l10n.get('context_menu_remove_from_playlist') + playlistName,
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

  _createRemoveFromHistoryMenuItem: (currentTrackContainer, options) ->
    artist = options.artist
    title = options.title

    return new gui.MenuItem(
      label: l10n.get('context_menu_remove_from_history'),
      click: ->
        History.removeTrack(
          artist,
          title
        )
        currentTrackContainer.remove()
        userTracking.event(
          'History',
          'Remove Track from History'
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

  _createCopyVideoUrlMenuItem : (options) ->
    artist = options.artist
    title = options.title
    return new gui.MenuItem(
      label: l10n.get('copy_video_url'),
      click: ->
        request
          url: 'http://gdata.youtube.com/feeds/api/videos?alt=json&' +
          'max-results=1&q=' + encodeURIComponent(artist + ' - ' + title)
          json: true,
          (error, response, data) ->
            if not data.feed.entry # no results
              alertify.log l10n.get('link_not_found')
              console.log l10n.get('link_not_found')
            else
              link = data.feed.entry[0].link[0].href
              clipboard = gui.Clipboard.get()
              clipboard.set link, 'text'
    )
