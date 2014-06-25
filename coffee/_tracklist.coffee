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