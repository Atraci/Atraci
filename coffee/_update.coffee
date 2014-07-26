request = require('request')

request
  url: Settings.get('updateUrl')
  json: true
, (error, response, data) ->
  if not error and response.statusCode is 200
    if data.updateUrl and data.downloadUrl
      Settings.set('updateUrl', data.updateUrl)

    if data[getOperatingSystem()]
      latestVersion = data[getOperatingSystem()].version
      latestDescription = data[getOperatingSystem()].description

      if versionCompare(latestVersion, gui.App.manifest.version) == 1
        alertify.confirm("
          A new version of Atraci is available (#{latestVersion})!\n\n
          By pressing OK, you will be redirected to the website where
          you can download the latest version.\n\nWhat\'s New:\n
          #{latestDescription}
        ", (e) ->
          if e
            gui.Shell.openExternal(data.downloadUrl)
        )

versionCompare = (left, right) ->
  return false unless typeof left + typeof right is "stringstring"
  a = left.split(".")
  b = right.split(".")
  i = 0
  len = Math.max(a.length, b.length)
  while i < len
    if (a[i] and not b[i] and parseInt(a[i]) > 0) or
    (parseInt(a[i]) > parseInt(b[i]))
      return 1
    else if (b[i] and not a[i] and parseInt(b[i]) > 0) or
    (parseInt(a[i]) < parseInt(b[i]))
      return -1
    i++
  0
