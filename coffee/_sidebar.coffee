populateSidebar = (playlists) ->
    currentlyActive = $('#sidebar-container ul li.active').text()
    $('#sidebar-container ul').empty()

    $('#sidebar-container ul').append('<li class="top">Top Tracks</li>')
    $('#sidebar-container ul').append('<li class="sep"><hr></li>')

    $('#sidebar-container ul').append('<li class="history">History</li>')
    $('#sidebar-container ul').append('<li class="sep"><hr></li>')
    
    for playlist in playlists
        $('#sidebar-container ul').append('<li class="playlist">' + playlist.name + '</li>')
    $('#sidebar-container ul').append('<li class="new">+ New playlist</li>')
    
    # Re-active context after repopulating
    $('#sidebar-container ul li').filter(->
        $(@).text() == currentlyActive
    ).addClass('active')

$ ->
    $('#sidebar-container').on 'click', 'li.history, li.playlist, li.top', ->
        $(@).siblings('.active').removeClass('active')
        $(@).addClass('active')

    $('#sidebar-container').on 'click', 'li', ->
        if $(@).hasClass('top')
            $('#tracklist-container').empty()
            spinner = new Spinner(spinner_opts).spin($('#tracklist-container')[0])
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

    $('#sidebar-container ul').on 'click', 'li.new', ->
        new_playlist_name = prompt('Enter new playlist name:')
        if new_playlist_name
            Playlists.create(new_playlist_name)
            Playlists.getAll((playlists) ->
                populateSidebar(playlists)
                )
            userTracking.event("Playlist", "Create", new_playlist_name).send()

    $('#sidebar-container ul').on 'contextmenu', 'li.playlist', (e) ->
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
