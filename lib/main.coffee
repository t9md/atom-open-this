path = require 'path'
fs   = require 'fs-plus'

module.exports =
  wordRegex: /[-\w/\.]+/

  activate: (state) ->
    atom.commands.add 'atom-text-editor',
      'open-this:here':        => @open()
      'open-this:split-down':  => @open('down')
      'open-this:split-right': => @open('right')

  getExtensions: (editor) ->
    scopeName = editor.getGrammar().scopeName
    grammar   = atom.grammars.grammarForScopeName(scopeName)
    grammar.fileTypes ? []

  # Return first existing filePath from following list.
  #  [
  #   File with same extension to current file's
  #   File with extensions... from current Grammar.fileTypes
  #   File
  #   File have same basename
  #  ]
  detectFilePath: (file) ->
    editor   = atom.workspace.getActiveTextEditor()
    extname  = path.extname editor.getURI()
    dirName  = path.dirname file
    baseName = path.basename file, extname

    extensions = []
    # ext of current file.
    extensions.push extname.substr(1) if extname
    # ext of Grammar.fileTypes
    extensions = extensions.concat @getExtensions(editor)
    files = extensions.map (ext) -> "#{file}.#{ext}"

    # file as-is
    files.push file

    # Search existing file from file list.
    for file in files
      if fs.existsSync(file) and fs.lstatSync(fs.realpathSync(file))?.isFile()
        return file

    # Search file have same basename.
    for file in fs.listSync(dirName)
      if path.basename(file, path.extname(file)) is baseName
        return file

  open: (split) ->
    editor  = atom.workspace.getActiveTextEditor()
    URI     = editor.getURI()
    range   = editor.getLastCursor().getCurrentWordBufferRange({@wordRegex})
    dirName = path.dirname URI

    return unless fileName = editor.getTextInBufferRange(range)
    return unless filePath = @detectFilePath path.resolve(dirName, fileName)

    pane = atom.workspace.getActivePane()
    switch split
      when 'down'  then pane.splitDown()
      when 'right' then pane.splitRight()

    atom.workspace.open(filePath, searchAllPanes: false).done ->

  deactivate: ->
