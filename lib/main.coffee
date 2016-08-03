path = require 'path'
fs = require 'fs-plus'
_ = require 'underscore-plus'

getBaseName = (file) ->
  path.basename(file, path.extname(file))

getExtensionsForScope = (scopeName) ->
  grammar = atom.grammars.grammarForScopeName(scopeName)
  grammar.fileTypes ? []

commandsDisposer = null
FileNameRegexp = /[-\w/\.]+(:\d+){0,2}/g

module.exports =
  activate: (state) ->
    commandsDisposer = atom.commands.add 'atom-text-editor',
      'open-this:here': => @open()
      'open-this:split-down': => @open('down')
      'open-this:split-right': => @open('right')

  deactivate: ->
    commandsDisposer?.dispose()

  getFiles: (file) ->
    editor = atom.workspace.getActiveTextEditor()
    exts = []

    if extname = path.extname(editor.getURI()) # ext of current file.
      exts.push extname.substr(1)

    exts = exts.concat getExtensionsForScope(editor.getGrammar().scopeName)
    files = ("#{file}.#{ext}" for ext in exts)
    files.push file
    _.uniq files

  # Return first existing filePath in following order.
  #  - File with same extension to current file's
  #  - File with extensions... from current Grammar.fileTypes
  #  - File
  #  - File have same basename
  detectFilePath: (filePath) ->
    # Search existing file from file list.
    file = _.detect @getFiles(filePath), (f) ->
      fs.existsSync(f) and fs.lstatSync(fs.realpathSync(f))?.isFile()
    return file if file?

    # Search file have same basename.
    baseName = getBaseName(filePath)
    _.detect fs.listSync(path.dirname(filePath)), (f) ->
      getBaseName(f) is baseName

  getFilePath: (editor, fileName) ->
    dirName = path.dirname(editor.getURI())

    if filePath = @detectFilePath(path.resolve(dirName, fileName))
      return filePath

    # Surpport git diff output
    if fileName.match(/^[ab]\//)
      fileName = fileName.replace(/^[ab]\//, '')
      return @detectFilePath(path.resolve(dirName, fileName))

    # Search from projectRoot
    for dir in atom.project.getPaths() when dirName.startsWith(dir)
      return @detectFilePath(path.resolve(dir, fileName))
    null

  open: (split) ->
    editor = atom.workspace.getActiveTextEditor()
    cursorPosition = editor.getCursorBufferPosition()
    scanRange = editor.bufferRangeForBufferRow(cursorPosition.row)

    fileName = null
    editor.scanInBufferRange FileNameRegexp, scanRange, ({range, matchText, stop}) ->
      if range.containsPoint(cursorPosition)
        fileName = matchText
        stop()
    return unless fileName

    [fileName, line, column] = fileName.split(":")
    return unless filePath = @getFilePath(editor, fileName)
    pane = atom.workspace.getActivePane()
    switch split
      when 'down' then pane.splitDown()
      when 'right' then pane.splitRight()

    options = {searchAllPanes: false}
    options.initialLine = (line - 1) if line?
    options.initialColumn = (column - 1) if column?
    atom.workspace.open(filePath, options)
