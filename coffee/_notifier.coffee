# global Settings
class Notifier
  @show: (options) ->
    title = options.title || ''
    body = options.body || ''
    icon = options.icon || ''

    if Settings.get('enable-notification') is "true"
      notify = new Notification(title, {
        body: body,
        icon: icon
      })

      notify.onclick = ->
        notify.close()
        gui.Window.get().focus()
