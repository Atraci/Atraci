class Notify

  emit: (title, options) ->
    if document.webkitHidden #window is minimized
      new Notification(title,
            body: options.body
            icon: options.link
            )
    else
    return false

