$ ->
    $('#Search input').keypress (e) ->
        if e.which is 13 and $(@).val() != ''
            userTracking.event("Search", "organic", $(@).val()).send()
            $('#SideBar li.active').removeClass('active')
            $('#ContentWrapper').empty()
            spinner = new Spinner(spinner_opts).spin($('#ContentWrapper')[0])

            TrackSource.search($(@).val(), ((tracks) ->
                spinner.stop()
                PopulateTrackList(tracks)
            ))

    $('#ContentWrapper').on 'click', '.track-container', ->
      if videojs('video_player').paused() != true && videojs('video_player').currentTime() == 0 && !$(@).find('.artist').text() || $(@).find('.artist').text() != __currentTrack.artist && !$(@).find('.title').text() || $(@).find('.title').text() != __currentTrack.title
        PlayTrack($(@).find('.artist').text(), $(@).find('.title').text(), $(@).find('.cover').attr('data-cover_url_medium'), $(@).find('.cover').attr('data-cover_url_large'))
        $(@).siblings('.playing').removeClass('playing')
        $(@).addClass('playing')
        console.log(videojs('video_player').paused())
      else if videojs('video_player').paused()
        videojs('video_player').play()
      else
        videojs('video_player').pause()
