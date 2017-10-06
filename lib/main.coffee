path = require 'path'
fs = require 'fs-plus'
_ = require 'underscore-plus'

hasCommonJSPackageSemantics = (scopeName, filePath) ->
  # why use `startsWith` is to make `source.js.jsx` true.
  fs.isDirectorySync(filePath) and (scopeName.startsWith('source.js') or scopeName.startsWith('source.coffee'))

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

    {scopeName} = editor.getGrammar()

    exts = exts.concat(getExtensionsForScope(scopeName))
    files = ("#{file}.#{ext}" for ext in exts)
    files.push(file)

    _.uniq(files)

  # Return first existing filePath in following order.
  #  - File with same extension to current file's
  #  - File with extensions... from current Grammar.fileTypes
  #  - File have same basename
  detectFilePath: (filePath) ->
    # Search existing file from file list.
    if file = @getFiles(filePath).find((f) -> fs.isFileSync(f))
      return file

    # Search file have same basename.
    baseName = getBaseName(filePath)
    fs.listSync(path.dirname(filePath)).find (f) ->
      (getBaseName(f) is baseName) and fs.isFileSync(f)

  getFilePath: (editor, fileName) ->
    dirName = path.dirname(editor.getURI())

    {scopeName} = editor.getGrammar()
    filePath = path.resolve(dirName, fileName)
    if hasCommonJSPackageSemantics scopeName, filePath
      extensions = ['.js', '.coffee', '.jsx']
      indexFilePath = extensions
        .map (ext) -> path.join(filePath, "index#{ext}")
        .find (indexFilePath) -> fs.isFileSync(indexFilePath)
      return indexFilePath if indexFilePath

    if filePath = @detectFilePath(path.resolve(dirName, fileName))
      return filePath

    # If grammar was sass or scss we try to find partial file which
    # starts with underscore.
    if scopeName in ['source.sass', 'source.css.scss']
      [precedings..., lastPart] = fileName.split(path.sep)
      sassPartialFileName = path.join([precedings..., "_" + lastPart]...)
      return @detectFilePath(path.resolve(dirName, sassPartialFileName))

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
