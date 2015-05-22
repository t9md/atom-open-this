path = require 'path'
fs   = require 'fs'

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
    grammar.fileTypes or []

  detectFilePath: (filePath) ->
    #
    # Return first existing filePath from following list.
    # * filePath is absolute filePath under cursor.
    #  [
    #   filePath with exntame_of_current_file,
    #   filePath with extensions.. from current Grammar::fileTypes
    #   fileName
    #  ]
    editor    = atom.workspace.getActiveTextEditor()
    extname   = path.extname editor.getURI()

    extensions = []
    extensions.push extname.substr(1) if extname
    extensions = extensions.concat @getExtensions(editor)
    files      = extensions.map (ext) -> "#{filePath}.#{ext}"

    # Last candidate is original filePath
    files.push filePath

    for file in files
      if fs.existsSync(file)
        return file

  open: (split) ->
    editor  = atom.workspace.getActiveTextEditor()

    URI      = editor.getURI()
    baseDir  = path.dirname URI
    range    = editor.getLastCursor().getCurrentWordBufferRange({@wordRegex})
    fileName = editor.getTextInBufferRange(range)

    return unless fileName

    filePath = @detectFilePath path.resolve(baseDir, fileName)

    return unless filePath

    activePane = atom.workspace.getActivePane()
    switch split
      when 'down'  then activePane.splitDown()
      when 'right' then activePane.splitRight()

    atom.workspace.open(filePath, searchAllPanes: false).done ->

  deactivate: ->
