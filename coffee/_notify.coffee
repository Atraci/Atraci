class Notify
	
	 NowPlaying: (artist, title) ->
		  if document.webkitHidden #window is not visible
		  	 cover = playerContainer.find(".cover").css("background-image")
		  	 link = cover.replace(/.*\s?url\([\'\"]?/, "").replace(/[\'\"]?\).*/, "")

		  	 new Notification("Now Playing",
		  	 	body: artist + ' - ' + title
		  	 	icon: link
		  	 	)
		  else
		  return false

