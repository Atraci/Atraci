request = require('request')
ytdl = require('ytdl')

itag_priorities = [ # http://en.wikipedia.org/wiki/YouTube > Comparison of YouTube media encoding options
    85,
    84,
    43, # video, VP8/Vorbis/128 (0.6 mbps total)
    82
]

video_error_codes = {
    1: 'MEDIA_ERR_ABORTED',
    2: 'MEDIA_ERR_NETWORK',
    3: 'MEDIA_ERR_DECODE',
    4: 'MEDIA_ERR_SRC_NOT_SUPPORTED'
}

__LastSelectedTrack = null

__currentTrack = {}

__playerTracklist = []

spinner_cover = null

PlayNext = (artist, title, success) ->
    $.each __playerTracklist, (i, track) ->
        if track.artist == artist and track.title == title
            $('#tracklist-container .track-container').removeClass('playing');
            if i < __playerTracklist.length - 1
                t = __playerTracklist[i+1]
                $('#tracklist-container .track-container').eq(i+1).addClass('playing');
            else
                t = __playerTracklist[0]
                $('#tracklist-container .track-container').eq(0).addClass('playing');


            PlayTrack(t.artist, t.title, t.cover_url_medium, t.cover_url_large)

PlayPrevious = (artist, title, success) ->
    $.each __playerTracklist, (i, track) ->
        if track.artist == artist and track.title == title
            $('#tracklist-container .track-container').removeClass('playing');
            if i == 0
                t = __playerTracklist[0]
                $('#tracklist-container .track-container').eq(0).addClass('playing');
            else
                t = __playerTracklist[i-1]
                $('#tracklist-container .track-container').eq(i-1).addClass('playing');


            PlayTrack(t.artist, t.title, t.cover_url_medium, t.cover_url_large)

PlayTrack = (artist, title, cover_url_medium, cover_url_large) ->

    userTracking.event("Player", "Play", artist + ' - ' + title).send()

    __currentTrack =
        artist: artist
        title: title

    __playerTracklist = __currentTracklist

    __CurrentSelectedTrack = Math.random()
    __LastSelectedTrack = __CurrentSelectedTrack

    videojs('video_player').pause().currentTime(0)

    History.addTrack(artist, title, cover_url_medium, cover_url_large)

    if spinner_cover
        $('#player-container #cover #loading-overlay').hide()
        spinner_cover.stop()

    $('#player-container #info #video-info').html('► Loading...')
    $('#player-container #info #track-info #artist, #title').empty()
    $('#player-container #duration, #current-time').text('0:00')
    $('#player-container #cover').css({'background-image': 'url(' + cover_url_large + ')'})

    $('#player-container #cover #loading-overlay').show()
    spinner_cover = new Spinner(spinner_cover_opts).spin($('#player-container #cover')[0])

    $('#player-container #progress-current').css({'width': '0px'}) # not working ?

    $('#player-container #info #track-info #artist').html(artist)
    $('#player-container #info #track-info #title').html(title)

    request
        url: 'http://gdata.youtube.com/feeds/api/videos?alt=json&max-results=1&q=' + encodeURIComponent(artist + ' - ' + title)
        json: true
    , (error, response, data) ->
        if not data.feed.entry # no results
            PlayNext(__currentTrack.artist, __currentTrack.title)
        else
            $('#player-container #info #video-info').html('► ' + data.feed.entry[0].title['$t'] + ' (' + data.feed.entry[0].author[0].name['$t'] + ')')

            ytdl.getInfo data.feed.entry[0].link[0].href, {downloadURL: true}, (err, info) ->
                if err
                    console.log err
                else
                    stream_urls = []
                    $.each info.formats, (i, format) ->
                        stream_urls[format.itag] = format.url

                    $.each itag_priorities, (i, itag) ->
                        if stream_urls[itag]
                            if __CurrentSelectedTrack == __LastSelectedTrack
                                videojs('video_player').src(stream_urls[itag]).play()
                                userTracking.event("Playback Info", "itag", itag).send()
                            return false


videojs('video_player')

# Keyboard control : space : play / pause; arrows : previous / next
$(document).keydown (e) ->
    if e.keyCode is 32 and e.target.tagName != 'INPUT'
        if videojs('video_player').paused()
            videojs('video_player').play()
        else
            videojs('video_player').pause()
        return false
    if e.keyCode is 37 and e.target.tagName != 'INPUT'
        PlayPrevious(__currentTrack.artist, __currentTrack.title)
    if e.keyCode is 39 and e.target.tagName != 'INPUT'
        PlayNext(__currentTrack.artist, __currentTrack.title)

$('#player-container #info #track-info #action i').click ->
    if $(@).hasClass('play')
        videojs('video_player').play()
    else
        videojs('video_player').pause()



videojs('video_player').ready ->
    @.on 'loadedmetadata', ->
        $('#player-container #duration').text(moment(@duration()*1000).format('m:ss'))
        $(".cur").removeClass("cur")
        $(".playing").addClass("cur")
        $(".playing .cover").before($("#video_player"));
        videojs('video_player').play()

    @.on 'timeupdate', ->
        $('#player-container #progress-current').css({'width': (this.currentTime() / this.duration()) * 100 + '%'})
        $('#player-container #current-time').text(moment(this.currentTime()*1000).format('m:ss'))

    @.on 'ended', ->
        PlayNext(__currentTrack.artist, __currentTrack.title)

    @.on 'play', ->
        if spinner_cover
            $('#player-container #cover #loading-overlay').hide()
            spinner_cover.stop()
        $('#player-container #info #track-info #action i.play').hide()
        $('#player-container #info #track-info #action i.pause').show()
    @.on 'pause', ->
        $('#player-container #info #track-info #action i.pause').hide()
        $('#player-container #info #track-info #action i.play').show()

    @.on 'error', (e) ->
        code = if e.target.error then e.target.error.code else e.code
        userTracking.event("Playback Error", video_error_codes[code], __currentTrack.artist + ' - ' + __currentTrack.title).send()
        alert 'Playback Error (' + video_error_codes[code] + ')'

$('#player-container #volume-bg').ready ->
    $('#player-container #controls #volume-icon #action i.fa-volume-down').hide()
    $('#player-container #controls #volume-icon #action i.fa-volume-off').hide()

$('#player-container #progress-bg').on 'click', (e) ->
    percentage = (e.pageX - $(this).offset().left) / $(this).width()
    videojs('video_player').currentTime(percentage * videojs('video_player').duration())
    $('#player-container #progress-current').css({'width': (percentage) * 100 + '%'})

$('#player-container #volume-bg').on 'click', (e) ->
    percentage = (e.pageX - $(this).offset().left) / $(this).width()
    videojs('video_player').volume(percentage)
    $('#player-container #volume-current').css({'width': (percentage) * 100 + '%'})
    if percentage > 0.5
        $('#player-container #controls #volume-icon #action i.fa-volume-up').show()
        $('#player-container #controls #volume-icon #action i.fa-volume-down').hide()
        $('#player-container #controls #volume-icon #action i.fa-volume-off').hide()
    else if percentage < 0.5 and percentage > 0.1
        $('#player-container #controls #volume-icon #action i.fa-volume-up').hide()
        $('#player-container #controls #volume-icon #action i.fa-volume-down').show()
        $('#player-container #controls #volume-icon #action i.fa-volume-off').hide()
    else
        $('#player-container #controls #volume-icon #action i.fa-volume-up').hide()
        $('#player-container #controls #volume-icon #action i.fa-volume-down').hide()
        $('#player-container #controls #volume-icon #action i.fa-volume-off').show()
    console.log(percentage)

$('#player-container #track-info #prev').on 'click', (e) ->
    PlayPrevious(__currentTrack.artist, __currentTrack.title)

$('#player-container #track-info #next').on 'click', (e) ->
    PlayNext(__currentTrack.artist, __currentTrack.title)
    $('#tracklist-container').animate({ scrollTop: (+$(".track-container.playing").position().top)})