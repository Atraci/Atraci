track_menu = new gui.Menu()
track_menu.append new gui.MenuItem(label: 'Add to Favorites')

currentContextTrack = null

__currentTracklist = []
__artistObject = {}

PopulateTrackList = (tracks, artistObject, fromSort) ->
    if tracks.length > 0 && !fromSort
        for x of tracks
            tracks[x].id = x

    tracks = sortTracklist tracks
    $('#ContentWrapper').empty().scrollTop()

    if(artistObject)
        __artistObject = artistObject

    if(__artistObject && $("#SideBar .active").hasClass("featured"))
        $("#tmpl-artistPage").tmpl(__artistObject).prependTo('#ContentWrapper')

    if tracks.length > 0
        $('#tmpl-tracklist').tmpl(tracks).appendTo('#ContentWrapper')
        __currentTracklist = tracks
        calculateDivsInRow()
    else
        $('#tmpl-tracklist-error').tmpl({message: 'No tracks'}).appendTo('#ContentWrapper')


$ ->
    $('#ContentWrapper').on 'contextmenu', '.track-container', (e) ->
        _this = $(@)
        e.stopPropagation()
        menu = new gui.Menu()
        $.each __playlists, (k, playlist) ->
            menu.append new gui.MenuItem(
                label: 'Add to ' + playlist.name,
                click: ->
                    Playlists.addTrack(
                        _this.find('.artist').text(),
                        _this.find('.title').text(),
                        _this.find('.cover').attr('data-cover_url_medium'),
                        _this.find('.cover').attr('data-cover_url_large'),
                        playlist.name
                        )
                    userTracking.event("Playlist", "Add Track to Playlist", playlist.name).send()
                )


            menu.append new gui.MenuItem(
                label: 'Copy HTTP Link',
                click: ->
                    artist = _this.find('.artist').text()
                    title = _this.find('.title').text()
                    request
                       url: 'http://gdata.youtube.com/feeds/api/videos?alt=json&max-results=1&q=' + encodeURIComponent(artist + ' - ' + title)
                       json: true
                       , (error, response, data) ->
                            if not data.feed.entry # no results
                                console.log('No results')
                            else
                                link = data.feed.entry[0].link[0].href
                                clipboard.set(link, 'text')
                )

        if $('#SideBar li.active').hasClass('playlist')
            menu.append new gui.MenuItem(type: 'separator')
            playlist_name = $('#SideBar li.active').text()
            menu.append new gui.MenuItem(
                label: 'Remove from ' + playlist_name,
                click: ->
                    Playlists.removeTrack(
                        _this.find('.artist').text(),
                        _this.find('.title').text(),
                        playlist_name
                        )
                    _this.remove()
                    userTracking.event("Playlist", "Remove Track to Playlist", playlist_name).send()
                )
        
        menu.popup e.clientX, e.clientY
        false

    $(".trackListToolbar i").click ->
        $(".trackListToolbar i").removeClass("active");
        $(@).addClass("active")
        if($(@).hasClass("fa-th"))
            $('#ContentWrapper').removeClass("smallRows");
        else
            $('#ContentWrapper').addClass("smallRows");

    # Add to Favorites
    track_menu.items[0].click = ->
        Playlists.addTrack(
            currentContextTrack.find('.artist').text(),
            currentContextTrack.find('.title').text(),
            currentContextTrack.find('.cover').attr('data-cover_url_medium'),
            currentContextTrack.find('.cover').attr('data-cover_url_large'),
            'Favorites'
            )


calculateDivsInRow = ->
  $(".ghost").remove()
  divsInRow = 0
  $("#ContentWrapper .track-container").each ->
    if $(this).prev().length > 0
      return false  unless $(this).position().top is $(this).prev().position().top
      divsInRow++
    else
      divsInRow++
    return

  divsInLastRow = $("#ContentWrapper .track-container").length % divsInRow
  divsInLastRow = divsInRow  if divsInLastRow is 0
  to_add = divsInRow - divsInLastRow
  while to_add > 0
    $("#ContentWrapper").append $("<div/>").addClass("track-container ghost")
    to_add--
  return

window.onresize = ->
  clearTimeout addghost
  addghost = setTimeout(calculateDivsInRow, 100)
  return