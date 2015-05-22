path = require 'path'
fs   = require 'fs'

module.exports =
  wordRegex: /[-\w/\.]+/

  activate: (state) ->
    atom.commands.add 'atom-text-editor',
      'open-this:here':        => @open()
      'open-this:split-down':  => @open('down')
      'open-this:split-right': => @open('right')

  open: (split) ->
    console.log split
    editor  = atom.workspace.getActiveTextEditor()
    URI     = editor.getURI()
    extname = path.extname URI
    baseDir = path.dirname URI

    range     = editor.getLastCursor().getCurrentWordBufferRange({@wordRegex})
    fileName  = editor.getTextInBufferRange(range)
    filePath  = path.resolve(baseDir, fileName) + extname
    console.log filePath

    return unless fs.existsSync(filePath)

    activePane = atom.workspace.getActivePane()
    switch split
      when 'down'  then activePane.splitDown()
      when 'right' then activePane.splitRight()

    atom.workspace.open(filePath, searchAllPanes: false).done ->

  deactivate: ->
