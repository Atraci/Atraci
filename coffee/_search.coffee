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
        PlayTrack($(@).find('.artist').text(), $(@).find('.title').text(), $(@).find('.cover').attr('data-cover_url_medium'), $(@).find('.cover').attr('data-cover_url_large'))
        $(@).siblings('.playing').removeClass('playing')
        $(@).addClass('playing')