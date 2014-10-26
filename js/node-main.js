process.on('uncaughtException', function(error) {
  // Catch the error
  // Send report via google analytics here
  console.log('Uncaught node.js on ' + window.getOperatingSystem() + ' | Error: ', error);
  setTimeout(function() {
    window.location.reload();
    setTimeout(function() {
      window.alertify.error("Oops! Something went wrong.");
      window.userTracking.event("Error", "uncaughtException", window.getOperatingSystem(), error).send()
    }, 500);
  }, 200);
});
