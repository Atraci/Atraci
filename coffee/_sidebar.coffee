populateSidebar = (playlists) ->
  currentlyActive = $('#SideBar ul li.active').text()
  $('#SideBar ul').empty()

  $('#SideBar ul').append(
    "
      <li class='top'>
        <i class='fa fa-music'></i>
        <span data-l10n-id='top_track'>Top Tracks</span>
      </li>
    "
  )

  $('#SideBar ul').append(
    "
      <li class='featured'>
        <i class='fa fa-users'></i>
        <span data-l10n-id='featured_artist'>Featured Artist</span>
      </li>
    "
  )

  $('#SideBar ul').append(
    "
      <li class='sep'>
        <hr>
      </li>
    "
  )

  $('#SideBar ul').append(
    "
      <li class='history'>
        <i class='fa fa-history'></i>
        <span data-l10n-id='history'>History</span>
      </li>
    "
  )
  $('#SideBar ul').append(
    "
      <li class='sep'>
        <hr>
      </li>
    "
  )

  $('#SideBar ul').append(
    "
      <li class='new'>
        <i class='fa fa-plus-square'></i>
        <span data-l10n-id='new_playlist'>New playlist</span>
      </li>
    "
  )

  for playlist in playlists
    $('#SideBar ul').append(
      "
        <li class='playlist' data-name='#{playlist.name}'>#{playlist.name}</li>
      "
    )
  
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
    alertify.prompt l10n.get('create_playlist_popup'), (e, str) ->
      if !e
        return
      else
        Playlists.create(str)
        Playlists.getAll((playlists) ->
          populateSidebar(playlists)
        )
        userTracking.event("Playlist", "Create", str).send()

  $('#SideBar ul').on 'contextmenu', 'li.playlist', (e) ->
    playlist_name = $(@).text()
    e.stopPropagation()
    menu = new gui.Menu()
    menu.append new gui.MenuItem(
      label: 'Delete ' + $(@).text(),
      click: ->
        alertify.confirm l10n.get('delete_playlist_popup'), (e) ->
          if e
            $("#SideBar [data-name=" + playlist_name + "]").remove()
            Playlists["delete"] playlist_name
            Playlists.getAll (playlists) ->
              populateSidebar playlists
            
            userTracking.event("Playlist", "Delete", playlist_name).send()
    )
        
    menu.append new gui.MenuItem(
      label: 'Rename ' + $(@).text(),
      click: ->
        alertify.prompt l10n.get('rename_playlist_popup'), (e, str) ->
          if e && str
            Playlists.rename(playlist_name, str)
            Playlists.getAll((playlists) ->
              populateSidebar(playlists)
            )
            userTracking.event("Playlist", "Rename", str).send()
          else
            return
        , playlist_name
    )

    menu.popup e.clientX, e.clientY
    false

loadFeaturedArtistPage = ->
  $.getJSON("http://getatraci.net/featured.json", (artistObject) ->
    doSearch artistObject.value, true, (tracks) ->
      PopulateTrackList(tracks, artistObject)
  )
  true
