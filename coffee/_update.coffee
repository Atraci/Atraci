request = require('request')

request
    url: Settings.get('updateUrl')
    json: true
, (error, response, data) ->
    if not error and response.statusCode is 200
        if data.updateUrl and data.downloadUrl
            Settings.set('updateUrl', data.updateUrl)
        if data[getOperatingSystem()]
            if versionCompare(data[getOperatingSystem()].version, gui.App.manifest.version) == 1
                if confirm('A new version of Atraci is available (' + data[getOperatingSystem()].version + ') !\n\nBy pressing OK, you will be redirected to the website where you can download the latest version.\n\nWhat\'s New:\n' + data[getOperatingSystem()].description)
                    gui.Shell.openExternal(data.downloadUrl)


versionCompare = (left, right) ->
    return false  unless typeof left + typeof right is "stringstring"
    a = left.split(".")
    b = right.split(".")
    i = 0
    len = Math.max(a.length, b.length)
    while i < len
        if (a[i] and not b[i] and parseInt(a[i]) > 0) or (parseInt(a[i]) > parseInt(b[i]))
            return 1
        else return -1  if (b[i] and not a[i] and parseInt(b[i]) > 0) or (parseInt(a[i]) < parseInt(b[i]))
        i++
    0