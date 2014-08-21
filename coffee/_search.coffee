doSearch = (searchVal, getTracks, callback) ->
  userTracking.event(
    "Search",
    "organic",
  searchVal).send()

  $('#sidebar-container li.active').removeClass('active')
  $('#tracklist-container').empty()

  spinner = new Spinner(spinner_opts).spin($('#tracklist-container')[0])
  TrackSource.search({
    keywords: searchVal,
    type: 'default'
  }, ((tracks) ->
    if(!getTracks)
      spinner.stop()
      window.tracklist.populate(tracks)
    else
      callback tracks
  ))
$ ->
  $('#Search input').autocomplete(
    delay: 100
    messages:
      noResults: ''
      results:  ->
    select: (event, ui) ->
      doSearch(ui.item.value)
    source: (request, response) ->
      searchVal = request.term
      if searchVal
        $.getJSON(
          'http://www.last.fm/search/autocomplete?q=' + searchVal,
          (data) ->
            results = data?.response?.docs
            foundTracks = []
            if results
              results.forEach (eachItem, index) ->
                # find out the right type of this item
                if eachItem.track
                  itemType = 'Track'
                  itemValue = eachItem.artist + ' ' + eachItem.track
                else if eachItem.album
                  itemType = 'Album'
                  itemValue = eachItem.artist + ' ' + eachItem.album
                else if eachItem.artist
                  itemType = 'Artist'
                  itemValue = eachItem.artist
                else
                  # There may have no any value of these
                  # In this way, just ignore the case.
                  return

                foundTracks.push
                  type: itemType
                  weight: eachItem.weight
                  label: itemValue
                  value: itemValue

              # tracks with higher scores will be the first
              foundTracks.sort (trackA, trackB) ->
                return trackA.weight < trackB.weight

            response(foundTracks)
        )
      else
        response([])
  ).data('ui-autocomplete')._renderItem = (ul, item) ->
    # make icon
    iconClass = ''

    switch item.type
      when 'Track' then iconClass = 'fa-music'
      when 'Album' then iconClass = 'fa-folder-open-o'
      when 'Artist' then iconClass = 'fa-group'

    $icon = $('<span>')
    $icon.addClass('fa fa-fw ' + iconClass)

    # make label
    $label = $('<span>')
    $label.text(item.label)

    # make anchor
    $a = $('<a>')
    $a.append($icon)
    $a.append($label)

    return $('<li>')
      .data("item.autocomplete", item)
      .append($a)
      .appendTo(ul)

  $('#Search input').keypress (e) ->
    searchVal = $(@).val()
    if e.which is 13 and $(@).val() != ''
      doSearch(searchVal)

  $('#ContentWrapper').on 'click', '.track-container', ->
    if videojs('video_player').paused() != true and
    videojs('video_player').currentTime() == 0
      PlayTrack(
        $(@).find('.artist').text(),
        $(@).find('.title').text(),
        $(@).find('.cover').attr('data-cover_url_medium'),
        $(@).find('.cover').attr('data-cover_url_large')
      )
      $(@).siblings('.playing').removeClass('playing')
      $(@).addClass('playing')

    if $(@).find('.artist').text() != __currentTrack.artist or
    $(@).find('.title').text() != __currentTrack.title
      PlayTrack(
        $(@).find('.artist').text(),
        $(@).find('.title').text(),
        $(@).find('.cover').attr('data-cover_url_medium'),
        $(@).find('.cover').attr('data-cover_url_large')
      )
      $(@).siblings('.playing').removeClass('playing')
      $(@).addClass('playing')
    else if videojs('video_player').paused()
      videojs('video_player').play()
    else
      videojs('video_player').pause()
