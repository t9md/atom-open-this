path = require 'path'
fs   = require 'fs-plus'
_ = require 'underscore-plus'

getBaseName = (file) ->
  path.basename(file, path.extname(file))

getExtensions = (editor) ->
  scopeName = editor.getGrammar().scopeName
  grammar   = atom.grammars.grammarForScopeName(scopeName)
  grammar.fileTypes ? []

module.exports =
  wordRegex: /[-\w/\.]+/

  activate: (state) ->
    atom.commands.add 'atom-text-editor',
      'open-this:here': => @open()
      'open-this:split-down': => @open('down')
      'open-this:split-right': => @open('right')

  getFiles: (dir, file) ->
    editor = atom.workspace.getActiveTextEditor()
    exts = []

    if extname = path.extname(editor.getURI()) # ext of current file.
      exts.push extname.substr(1)

    files = [path.resolve(dir, file)]

    exts = exts.concat getExtensions(editor)
    files.unshift ("#{filePath}.#{ext}" for ext in exts for filePath in files)
    _.uniq _.flatten files

  # Return first existing filePath in following order.
  #  - File with same extension to current file's
  #  - File with extensions... from current Grammar.fileTypes
  #  - File
  #  - File have same basename
  detectFilePath: (dirName, filePath) ->
    # Search existing file from file list.
    file = _.detect @getFiles(dirName, filePath), (f) ->
      fs.existsSync(f) and fs.lstatSync(fs.realpathSync(f))?.isFile()
    return file if file?

    # Search file have same basename.
    file = path.resolve(dirName, filePath)
    baseName = getBaseName(file)
    file = _.detect fs.listSync(path.dirname(file)), (f) ->
      getBaseName(f) is baseName
    return file if file?

    file = path.resolve(dirName, filePath.replace(/^[ab]\//, ''))
    baseName = getBaseName(file)
    _.detect fs.listSync(path.dirname(file)), (f) ->
      getBaseName(f) is baseName

  open: (split) ->
    editor = atom.workspace.getActiveTextEditor()
    range = editor.getLastCursor().getCurrentWordBufferRange({@wordRegex})
    return unless fileName = editor.getTextInBufferRange(range)

    dirName = path.dirname(editor.getURI())

    return unless filePath = @detectFilePath(dirName, fileName)

    pane = atom.workspace.getActivePane()
    switch split
      when 'down' then pane.splitDown()
      when 'right' then pane.splitRight()

    atom.workspace.open(filePath, searchAllPanes: false)

  deactivate: ->
