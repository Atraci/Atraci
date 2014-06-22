populateSidebar = (playlists) ->
    currentlyActive = $('#SideBar ul li.active').text()
    $('#SideBar ul').empty()

    $('#SideBar ul').append('<li class="top"><i class="fa fa-th-large"></i>Top Tracks</li>')
    $('#SideBar ul').append('<li class="featured"><i class="fa fa-music"></i>Featured Artist</li>')
    $('#SideBar ul').append('<li class="sep"><hr></li>')

    $('#SideBar ul').append('<li class="history"><i class="fa fa-history"></i>History</li>')
    $('#SideBar ul').append('<li class="sep"><hr></li>')

    $('#SideBar ul').append('<li class="new"><i class="fa fa-plus-square"></i>New playlist</li>')
    for playlist in playlists
        $('#SideBar ul').append('<li class="playlist">' + playlist.name + '</li>')
    
    # Re-active context after repopulating
    $('#SideBar ul li').filter(->
        $(@).text() == currentlyActive
    ).addClass('active')

$ ->
    $('#SideBar').on 'click', 'li.history, li.playlist, li.top, li.featured', ->
        $(@).siblings('.active').removeClass('active')
        $(@).addClass('active')

    $('#SideBar').on 'click', 'li', ->
        if $(@).hasClass('top')
            $('#ContentWrapper').empty()
            spinner = new Spinner(spinner_opts).spin($('#ContentWrapper')[0])
            TrackSource.topTracks((tracks) ->
                spinner.stop()
                PopulateTrackList(tracks)
            )
        else if $(@).hasClass('history')
            TrackSource.history((tracks) ->
                PopulateTrackList(tracks)
            )
        else if $(@).hasClass('playlist')
            TrackSource.playlist($(@).text(), ((tracks) ->
                PopulateTrackList(tracks)
            ))
        else if $(@).hasClass('featured')
            loadFeaturedArtistPage()

    $('#SideBar ul').on 'click', 'li.new', ->
        new_playlist_name = prompt('Enter new playlist name:')
        if new_playlist_name
            Playlists.create(new_playlist_name)
            Playlists.getAll((playlists) ->
                populateSidebar(playlists)
            )
            userTracking.event("Playlist", "Create", new_playlist_name).send()

    $('#SideBar ul').on 'contextmenu', 'li.playlist', (e) ->
        playlist_name = $(@).text()
        e.stopPropagation()
        menu = new gui.Menu()
        menu.append new gui.MenuItem(
            label: 'Delete ' + $(@).text(),
            click: ->
                Playlists.delete(playlist_name)
                Playlists.getAll((playlists) ->
                    populateSidebar(playlists)
                    )
                userTracking.event("Playlist", "Delete", playlist_name).send()
            )
        menu.append new gui.MenuItem(
            label: 'Rename ' + $(@).text(),
            click: ->
                playlist_new_name = prompt("Set a new name", playlist_name)
                if playlist_new_name
                    Playlists.rename(playlist_name, playlist_new_name)
                    Playlists.getAll((playlists) ->
                        populateSidebar(playlists)
                    )
                    userTracking.event("Playlist", "Rename", playlist_name).send()
            )
        menu.popup e.clientX, e.clientY
        false

loadFeaturedArtistPage = ->
    $.getJSON("http://getatraci.net/featured.json", (artistObject) ->
        doSearch artistObject.value, true, (tracks) ->
            PopulateTrackList(tracks, artistObject)
    )
    true
