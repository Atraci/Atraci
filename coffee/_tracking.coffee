os = require('os')

getTrackingId = ->
    clientId = Settings.get("trackingId")
    if typeof clientId is "undefined" or not clientId? or clientId is ""
        
        # A UUID v4 (random) is the recommended format for Google Analytics
        uuid = require("node-uuid")
        Settings.set "trackingId", uuid.v4()
        clientId = Settings.get("trackingId")
        
        # Try a time-based UUID (v1) if the proper one fails
        if typeof clientId is "undefined" or not clientId? or clientId is ""
            Settings.set "trackingId", uuid.v1()
            clientId = Settings.get("trackingId")
            if typeof clientId is "undefined" or not clientId? or clientId is ""
                clientId = null
    clientId

ua = require("universal-analytics")
unless getTrackingId()?
    
    # Don't report anything if we don't have a trackingId
    dummyMethod = ->
        send: ->

    userTracking = window.userTracking =
        event: dummyMethod
        pageview: dummyMethod
        timing: dummyMethod
        exception: dummyMethod
        transaction: dummyMethod
else
    userTracking = window.userTracking = ua("UA-49098639-1", getTrackingId())

# Detect the operating system of the user
getOperatingSystem = ->
    platform = os.platform()
    return "windows"  if platform is "win32" or platform is "win64"
    return "mac"  if platform is "darwin"
    return "linux"  if platform is "linux"
    null


# General Device Stats
userTracking.event("Device Stats", "Version", gui.App.manifest.version).send()
userTracking.event("Device Stats", "Type", getOperatingSystem()).send()
userTracking.event("Device Stats", "Operating System", os.type() + " " + os.release()).send()
userTracking.event("Device Stats", "CPU", os.cpus()[0].model + " @ " + (os.cpus()[0].speed / 1000).toFixed(1) + "GHz" + " x " + os.cpus().length).send()
userTracking.event("Device Stats", "RAM", Math.round(os.totalmem() / 1024 / 1024 / 1024) + "GB").send()
userTracking.event("Device Stats", "Uptime", Math.round(os.uptime() / 60 / 60) + "hs").send()
    
# Screen resolution, depth and pixel ratio (retina displays)
if typeof screen.width is "number" and typeof screen.height is "number"
    resolution = (screen.width).toString() + "x" + (screen.height.toString())
    resolution += "@" + (screen.pixelDepth).toString()  if typeof screen.pixelDepth is "number"
    resolution += "#" + (window.devicePixelRatio).toString()  if typeof window.devicePixelRatio is "number"
    userTracking.event("Device Stats", "Resolution", resolution).send()
    
# User Language
userTracking.event("Device Stats", "Language", navigator.language.toLowerCase()).send()

# Track one page view at launch
userTracking.pageview("/").send()

# Keep session alive to get actual session durations in GA
setInterval (->
    userTracking.event("_KeepAlive", "Pulse").send()
), 600*1000 # every 10 minutes