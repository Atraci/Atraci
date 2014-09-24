
class FileDialog

  @saveAs: (opts, cb) ->
    $('#saveAs').remove() # remove old dialogs
    chooser = $('<input type="file" id="saveAs" nwsaveas />')
    chooser.attr('nwworkingdir', opts.dir) if opts.dir?
    chooser.attr('nwsaveas', opts.name) if opts.name?
    chooser.appendTo('body')
    chooser.change ->
      cb(chooser.val())
      # Reset the selected value to empty ('')
      chooser.val('')
    chooser.trigger 'click'
