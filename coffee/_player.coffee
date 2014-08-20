request = require('request')
ytdl = require('ytdl')
playerContainer = $('#PlayerContainer')
videoContainer = $('#video-container')

# http://en.wikipedia.org/wiki/YouTube > Comparison
# of YouTube media encoding options
itag_priorities = [
  85,
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

isBusyBuffering = 0

PlayNext = (artist, title, success) ->
  $.each __playerTracklist, (i, track) ->
    if track.artist == artist and track.title == title
      $('#ContentWrapper .track-container').removeClass('playing')
      if i < __playerTracklist.length - 1
        t = __playerTracklist[i + 1]
        $('#ContentWrapper .track-container')
          .eq(i + 1)
          .addClass('playing')
      else
        t = __playerTracklist[0]
        $('#ContentWrapper .track-container')
          .eq(0)
          .addClass('playing')

      PlayTrack(t.artist, t.title, t.cover_url_medium, t.cover_url_large)

PlayPrevious = (artist, title, success) ->
  $.each __playerTracklist, (i, track) ->
    if track.artist == artist and track.title == title
      $('#ContentWrapper .track-container').removeClass('playing')
      if i == 0
        t = __playerTracklist[0]
        $('#ContentWrapper .track-container')
          .eq(0)
          .addClass('playing')
      else
        t = __playerTracklist[i-1]
        $('#ContentWrapper .track-container')
          .eq(i - 1)
          .addClass('playing')

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
    playerContainer.find('#cover #loading-overlay').hide()
    spinner_cover.stop()

  playerContainer
    .find('.info .video-info')
    .html('► Loading...')

  playerContainer
    .find('.info .track-info .artist,#PlayerContainer .title')
    .empty()

  playerContainer
    .find('.duration, .current-time')
    .text('0:00')

  playerContainer
    .find('.cover')
    .css({'background-image': 'url(' + cover_url_large + ')'})

  playerContainer
    .find('.cover #loading-overlay')
    .show()

  spinner_cover = new Spinner(spinner_cover_opts)
    .spin(playerContainer.find('.cover')[0])

  playerContainer
    .find('.progress-current')
    .css({'width': '0px'}) # not working ?

  playerContainer
    .find('.info .track-info .artist')
    .html(artist)

  playerContainer
    .find('.info .track-info .title')
    .html(title)

  playerContainer
    .find('.info .track-info .related')
    .click ->
      if isBusyBuffering is 0
        artistRecommend =
          playerContainer
            .find('.info .track-info .artist')
            .text()
        titleRecommend =
          playerContainer
            .find('.info .track-info .title')
            .text()
        if artistRecommend and titleRecommend
          TrackSource.recommendations(artistRecommend, titleRecommend)
        else
          alertify.log l10n.get('select_song_wait')
      else
        alertify.log l10n.get('load_song_wait')
  request
    url:
      'http://gdata.youtube.com/feeds/api/videos?alt=json&max-results=1&q=' +
      encodeURIComponent(artist + ' - ' + title)
    json: true
  , (error, response, data) ->
    if not data.feed.entry # no results
      PlayNext(__currentTrack.artist, __currentTrack.title)
    else
      isBusyBuffering = 1
      playerContainer
        .find('#info #video-info')
        .html(
          "
            ► #{data.feed.entry[0].title['$t']} (
            #{data.feed.entry[0].author[0].name['$t']})
          "
        )

      ytdl.getInfo(
        data.feed.entry[0].link[0].href,
        {downloadURL: true},
        (err, info) ->
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
                  isBusyBuffering = 0
                return false
      )

videojs('video_player')

playerContainer
  .find('.info .track-info .action .play, .info .track-info .action .pause')
  .click ->
    if isBusyBuffering is 0
      if $(@).hasClass('play')
        videojs('video_player').play()
      else
        videojs('video_player').pause()

videojs('video_player').ready ->
  @.on 'loadedmetadata', ->
    playerContainer
      .find('.duration')
      .text(moment(@duration()*1000).format('m:ss'))

    videojs('video_player').play()

  @.on 'timeupdate', ->
    playerContainer
      .find('.progress-current')
      .css({'width': (this.currentTime() / this.duration()) * 100 + '%'})

    playerContainer
      .find('.current-time')
      .text(moment(this.currentTime() * 1000).format('m:ss'))
  @.on 'progress', ->
    playerContainer
      .find('.loading-progress')
      .css({'width': videojs('video_player').bufferedPercent() * 100 + '%'})
  @.on 'ended', ->
    isRepeat = playerContainer
      .find('.repeat')
      .closest(".action")
      .hasClass("active")

    isRandom = playerContainer
      .find('.random')
      .closest(".action")
      .hasClass("active")

    if isRepeat
      videojs('video_player').currentTime(0)
      videojs('video_player').play()
    else if isRandom
      t = __playerTracklist[Math.floor(
        Math.random() * __playerTracklist.length
      )]
      PlayTrack(t.artist, t.title, t.cover_url_medium, t.cover_url_large)
    else
      PlayNext(__currentTrack.artist, __currentTrack.title)

  @.on 'play', ->
    if spinner_cover
      playerContainer
        .find('.cover #LoadingOverlay')
        .hide()

      spinner_cover.stop()

    playerContainer
      .find('.info .track-info .action i.play')
      .hide()

    playerContainer
      .find('.info .track-info .action i.pause')
      .show()

  @.on 'pause', ->
    playerContainer
      .find('.info .track-info .action i.pause')
      .hide()

    playerContainer
      .find('.info .track-info .action i.play')
      .show()

  @.on 'error', (e) ->
    code = if e.target.error then e.target.error.code else e.code

    userTracking.event(
      "Playback Error",
      video_error_codes[code],
      __currentTrack.artist + ' - ' + __currentTrack.title
    ).send()

    alertify.alert 'Playback Error (' + video_error_codes[code] + ')'
    PlayNext(__currentTrack.artist, __currentTrack.title)

playerContainer.find('.volume-bg').ready ->
  playerContainer
    .find('.controls .volume-icon .action i.fa-volume-down')
    .hide()

  playerContainer
    .find('.controls .volume-icon #action i.fa-volume-off')
    .hide()

playerContainer.find('.progress-bg').on 'click', (e) ->
  percentage = (e.pageX - $(this).offset().left) / $(this).width()
  selectedTime = percentage * videojs('video_player').duration()
  videojs('video_player').currentTime(
    selectedTime
  )
  playerContainer
    .find('.progress-current')
    .animate({'width': (percentage) * 100 + '%'})

playerContainer.find('.volume-bg').on 'click', (e) ->
  percentage = (e.pageX - $(this).offset().left) / $(this).width()
  playerContainer.attr("data-volume", percentage)

  playerContainer
    .find('.volume-icon')
    .attr("data-ismuted", 0)

  playerContainer
    .find('.volume-icon')
    .find("i")
    .removeClass("fa-volume-off")
    .addClass("fa fa-volume-up")

  videojs('video_player')
    .volume(percentage)

  playerContainer
    .find('.volume-current')
    .animate({'width': (percentage) * 100 + '%'})

playerContainer.find('.track-info .backward').on 'click', (e) ->
  PlayPrevious(__currentTrack.artist, __currentTrack.title)

playerContainer.find('.track-info .forward').on 'click', (e) ->
  PlayNext(__currentTrack.artist, __currentTrack.title)

playerContainer.find('.track-info .repeat').on 'click', (e) ->
  $(@).closest(".action").toggleClass("active")

playerContainer.find('.track-info .random').on 'click', (e) ->
  $(@).closest(".action").toggleClass("active")

playerContainer.find('.volume-icon').on 'click', (e) ->
  if(+$(@).attr("data-ismuted") == 1)
    $(@).attr("data-ismuted", 0)
    $(@).find("i")
      .removeClass("fa-volume-off")
      .addClass("fa fa-volume-up")
    videojs('video_player')
      .volume(playerContainer.attr("data-volume"))
  else
    $(@).attr("data-ismuted", 1)
    $(@).find("i")
      .removeClass("fa-volume-up")
      .addClass("fa fa-volume-off")
    videojs('video_player').volume(0)

videoContainer.find(".ExpandButton").on "click", (e) ->
  $("#video-container").toggleClass "expanded"

videoContainer.find("#video_player").on "dblclick", (e) ->
  $("#video-container").toggleClass "expanded"

$('#PlayerContainer .progress-bg').on 'mousemove', (e) ->
  if videojs('video_player').currentTime() != 0
    percentage = ((e.pageX - $(this).offset().left) / $(this).width())
    time = percentage * videojs('video_player').duration()
    minutes = parseInt(time / 60) % 60
    seconds = parseInt(time % 60)

    if seconds < 10
      time = minutes + ":0" + seconds
    else
      time = minutes + ":" + seconds

    $('#PlayerContainer .mouse-time').show()
    $('#PlayerContainer .mouse-time').text(time)
    margin = e.pageX - 135
    $('#PlayerContainer .mouse-time').css({'margin-left': (margin) + 'px'})

$('#PlayerContainer .progress-bg').on 'mouseout', (e) ->
  $('#PlayerContainer .mouse-time').hide()

$(".currentHolder .artist"). on 'click', (e) ->
  $('#Search input').val(__currentTrack.artist)
  doSearch(__currentTrack.artist)

$(".currentHolder .artist"). on 'mousemove', (e) ->
  $(".currentHolder .curr-artist-search").show()
  $(".currentHolder .curr-artist-search")
  .text("Click to search for " + __currentTrack.artist)
  $(".currentHolder .curr-artist-search")
  .css({'background': 'rgba(0,0,0,.9)'})
  .css({'box-shadow': '0 0 2px rgba(0,0,0,.5)'})

$(".currentHolder .artist").on 'mouseout', (e) ->
  $(".currentHolder .curr-artist-search").hide()
  $(".currentHolder .curr-artist-search")
  .css({'background': '0'})
  .css({'box-shadow': '0'})