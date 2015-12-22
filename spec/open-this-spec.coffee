_  = require 'underscore-plus'
path = require 'path'
fs = require 'fs-plus'

getPath = ->
  atom.workspace.getActiveTextEditor().getPath()

filePathFor = (file) ->
  filePath = path.join "#{__dirname}/fixtures", file
  fs.normalize(filePath)

getPaneOrientation = (pane) ->
  pane.getContainer().getRoot().getOrientation()

openFile = (file, {scope, pack}, fn) ->
  waitsForPromise ->
    atom.packages.activatePackage(pack)

  grammar = atom.grammars.grammarForScopeName(scope)
  waitsForPromise ->
    atom.workspace.open(file).then (editor) ->
      editor.setGrammar(grammar)
      fn(editor)

dispatchCommand = (elem, command, fn) ->
  spy = jasmine.createSpy()
  atom.workspace.onDidChangeActivePaneItem(spy)
  atom.commands.dispatch(elem, command)

  waitsFor -> spy.callCount is 1
  runs -> fn()

dispatchSplitCommand = (elem, command, fn) ->
  spyPaneChange = jasmine.createSpy()
  spyOpen = jasmine.createSpy()

  atom.workspace.onDidChangeActivePane(spyPaneChange)
  atom.workspace.onDidChangeActivePaneItem(spyOpen)
  atom.commands.dispatch(elem, command)

  waitsFor -> spyPaneChange.callCount is 1
  waitsFor -> spyOpen.callCount is 2
  runs -> fn()

describe "open-this", ->
  [editor, editorElement, main, workspaceElement] = []

  beforeEach ->
    workspaceElement = atom.views.getView(atom.workspace)
    jasmine.attachToDOM(workspaceElement)

    topFile = atom.project.resolvePath "top.coffee"
    options = {scope: 'source.coffee', pack: 'language-coffee-script'}
    openFile topFile, options, (e) ->
      editor = e
      editor.setCursorBufferPosition [0, 0]
      editorElement = atom.views.getView(e)

    activationPromise = null
    runs ->
      activationPromise = atom.packages.activatePackage('open-this').then (pack) ->
        main = pack.mainModule
      atom.commands.dispatch(editorElement, 'open-this:here')

    waitsForPromise ->
      activationPromise

  describe "::getFiles", ->
    describe "CoffeeScript editor", ->
      it 'returns candidate file paths', ->
        [first, other..., last] = main.getFiles("sample")
        expect(first).toBe "sample.coffee"
        expect("sample.Cakefile" in other).toBe true
        expect("sample.cson" in other).toBe true
        expect(last).toBe "sample"

    describe "Ruby editor", ->
      beforeEach ->
        topFile = atom.project.resolvePath "top.rb"
        options = {scope: 'source.ruby', pack: 'language-ruby'}
        openFile topFile, options, (e) ->
          editor = e
          editor.setCursorBufferPosition [0, 0]
          editorElement = atom.views.getView(e)

      it 'returns candidate file paths', ->
        [first, other..., last] = main.getFiles("sample")
        expect(first).toBe "sample.rb"
        expect("sample.rake" in other).toBe true
        expect("sample.ru" in other).toBe true
        expect(last).toBe "sample"

  describe "open-this:here", ->
    describe "Coffee editor", ->
      it 'open file under cursor case-1', ->
        editor.setCursorBufferPosition [1, 3]
        dispatchCommand editorElement, 'open-this:here', ->
          expect(getPath()).toBe filePathFor('dir1/dir1.coffee')

      it 'open file under cursor case-2', ->
        editor.setCursorBufferPosition [2, 19]
        dispatchCommand editorElement, 'open-this:here', ->
          expect(getPath()).toBe filePathFor('dir1/dir1.coffee')

      it 'open file with same basename when no one found.', ->
        editor.setCursorBufferPosition [3, 2]
        dispatchCommand editorElement, 'open-this:here', ->
          expect(getPath()).toBe filePathFor('dir1/file1.json')

      it 'open file with no extension when no one found.', ->
        editor.setCursorBufferPosition [4, 2]
        dispatchCommand editorElement, 'open-this:here', ->
          expect(getPath()).toBe filePathFor('dir1/file2')

      it 'open file by removing leading "a" directory(git-diff output)', ->
        editor.setCursorBufferPosition [8, 2]
        dispatchCommand editorElement, 'open-this:here', ->
          expect(getPath()).toBe filePathFor('dir1/file1.json')

      it 'open file by removing leading "b" directory(git-diff output)', ->
        editor.setCursorBufferPosition [9, 2]
        dispatchCommand editorElement, 'open-this:here', ->
          expect(getPath()).toBe filePathFor('dir1/file2')

      describe "open file from relative to project root", ->
        beforeEach ->
          topFile = atom.project.resolvePath "dir1/from-project-root.coffee"
          options = {scope: 'source.coffee', pack: 'language-coffee-script'}
          openFile topFile, options, (e) ->
            editor = e
            editor.setCursorBufferPosition [0, 0]
            editorElement = atom.views.getView(e)

        # In spec, atom.project.getPaths() is set to
        #  "ROOT_DIR/atom-open-this/spec/fixtures"
        it 'open file from relative to current project root case-1', ->
          editor.setCursorBufferPosition [2, 2]
          dispatchCommand editorElement, 'open-this:here', ->
            expect(getPath()).toBe filePathFor('dir1/dir1.coffee')

        it 'open file from relative to current project root case-2', ->
          editor.setCursorBufferPosition [3, 2]
          dispatchCommand editorElement, 'open-this:here', ->
            expect(getPath()).toBe filePathFor('top.rb')

    describe "Ruby editor", ->
      beforeEach ->
        topFile = atom.project.resolvePath "top.rb"
        options = {scope: 'source.ruby', pack: 'language-ruby'}
        openFile topFile, options, (e) ->
          editor = e
          editor.setCursorBufferPosition [0, 0]
          editorElement = atom.views.getView(e)

      it 'open file under cursor case-1', ->
        editor.setCursorBufferPosition [1, 3]
        dispatchCommand editorElement, 'open-this:here', ->
          expect(getPath()).toBe filePathFor('dir1/dir1.rb')

      it 'open file under cursor case-2', ->
        editor.setCursorBufferPosition [2, 19]
        dispatchCommand editorElement, 'open-this:here', ->
          expect(getPath()).toBe filePathFor('dir1/dir1.rb')

      it 'open file with same basename when no one found.', ->
        editor.setCursorBufferPosition [3, 2]
        dispatchCommand editorElement, 'open-this:here', ->
          expect(getPath()).toBe filePathFor('dir1/file1.json')

      it 'open file with no extension when no one found.', ->
        editor.setCursorBufferPosition [4, 2]
        dispatchCommand editorElement, 'open-this:here', ->
          expect(getPath()).toBe filePathFor('dir1/file2')

  describe "split cousin", ->
    beforeEach ->
      editor.setCursorBufferPosition [1, 3]

    describe "open-this:split-down", ->
      it "open file in pane split-down", ->
        dispatchSplitCommand editorElement, 'open-this:split-down', ->
          expect(getPath()).toBe filePathFor('dir1/dir1.coffee')
          panes = atom.workspace.getPanes()
          activePane = atom.workspace.getActivePane()

          expect(panes).toHaveLength 2
          expect(panes.indexOf(activePane)).toBe 1
          expect(getPaneOrientation(activePane)).toBe 'vertical'

    describe "open-this:split-right", ->
      it "open file in pane split-right", ->
        dispatchSplitCommand editorElement, 'open-this:split-right', ->
          expect(getPath()).toBe filePathFor('dir1/dir1.coffee')
          panes = atom.workspace.getPanes()
          activePane = atom.workspace.getActivePane()

          expect(panes).toHaveLength 2
          expect(panes.indexOf(activePane)).toBe 1
          expect(getPaneOrientation(activePane)).toBe 'horizontal'
