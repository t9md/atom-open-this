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

  describe "::getCandidateFiles", ->
    describe "CoffeeScript editor", ->
      it 'returns candidate file paths', ->
        [first, other..., last] = main.getCandidateFiles("sample")
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
        [first, other..., last] = main.getCandidateFiles("sample")
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

      it 'open file with initial line specified by (:row)', ->
        editor.setCursorBufferPosition [13, 2]
        dispatchCommand editorElement, 'open-this:here', ->
          expect(getPath()).toBe filePathFor('dir1/file1.json')
          editor = atom.workspace.getActiveTextEditor()
          expect(editor.getCursorBufferPosition()).toEqual [1, 0]

      it 'open file with initial line and colum specified by (:row:column)', ->
        editor.setCursorBufferPosition [14, 2]
        dispatchCommand editorElement, 'open-this:here', ->
          expect(getPath()).toBe filePathFor('dir1/file1.json')
          editor = atom.workspace.getActiveTextEditor()
          expect(editor.getCursorScreenPosition()).toEqual [2, 4]

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

    describe "Sass editor", ->
      beforeEach ->
        topFile = atom.project.resolvePath "top.scss"
        options = {scope: 'source.css.scss', pack: 'language-sass'}
        openFile topFile, options, (e) ->
          editor = e
          editor.setCursorBufferPosition [0, 0]
          editorElement = atom.views.getView(e)

      it 'open file under cursor case-1', ->
        editor.setCursorBufferPosition [1, 12]
        dispatchCommand editorElement, 'open-this:here', ->
          expect(getPath()).toBe filePathFor('dir1/file1.scss')

      it 'open file under cursor case-2', ->
        editor.setCursorBufferPosition [2, 12]
        dispatchCommand editorElement, 'open-this:here', ->
          expect(getPath()).toBe filePathFor('dir1/_file3.scss')

    describe "JavaScript editor", ->
      beforeEach ->
        topFile = atom.project.resolvePath "top.js"
        options = {scope: 'source.js', pack: 'language-javascript'}
        openFile topFile, options, (e) ->
          editor = e
          editor.setCursorBufferPosition [0, 0]
          editorElement = atom.views.getView(e)

      it 'case-1: open file under cursor', ->
        editor.setCursorBufferPosition [0, 21]
        dispatchCommand editorElement, 'open-this:here', ->
          expect(getPath()).toBe filePathFor('dir1/dir1.js')

      it 'case-2: open index.js file under cursor', ->
        editor.setCursorBufferPosition [1, 25]
        dispatchCommand editorElement, 'open-this:here', ->
          expect(getPath()).toBe filePathFor('dir1/index.js')

      it 'case-3: open index.jsx file under cursor as a fallback', ->
        editor.setCursorBufferPosition [2, 25]
        dispatchCommand editorElement, 'open-this:here', ->
          expect(getPath()).toBe filePathFor('dir2/index.jsx')

    describe "JavaScript JSX editor", ->
      beforeEach ->
        topFile = atom.project.resolvePath "top.js"
        options = {scope: 'source.js', pack: 'language-javascript'}
        openFile topFile, options, (e) ->
          editor = e
          editor.setCursorBufferPosition [0, 0]
          editorElement = atom.views.getView(e)

      it 'case-1: open file under cursor', ->
        editor.setCursorBufferPosition [0, 21]
        dispatchCommand editorElement, 'open-this:here', ->
          expect(getPath()).toBe filePathFor('dir1/dir1.js')

      it 'case-2: open index.js file under cursor', ->
        editor.setCursorBufferPosition [1, 25]
        dispatchCommand editorElement, 'open-this:here', ->
          expect(getPath()).toBe filePathFor('dir1/index.js')

      it 'case-3: open index.jsx file under cursor as a fallback', ->
        editor.setCursorBufferPosition [2, 25]
        dispatchCommand editorElement, 'open-this:here', ->
          expect(getPath()).toBe filePathFor('dir2/index.jsx')

  describe "split cousin", ->
    beforeEach ->
      editor.setCursorBufferPosition [1, 3]

    describe "open-this:split-down", ->
      it "open file in pane split-down", ->
        dispatchSplitCommand editorElement, 'open-this:split-down', ->
          expect(getPath()).toBe filePathFor('dir1/dir1.coffee')
          panes = atom.workspace.getCenter().getPanes()
          activePane = atom.workspace.getActivePane()

          expect(panes).toHaveLength 2
          expect(panes.indexOf(activePane)).toBe 1
          expect(getPaneOrientation(activePane)).toBe 'vertical'

    describe "open-this:split-right", ->
      it "open file in pane split-right", ->
        dispatchSplitCommand editorElement, 'open-this:split-right', ->
          expect(getPath()).toBe filePathFor('dir1/dir1.coffee')
          panes = atom.workspace.getCenter().getPanes()
          activePane = atom.workspace.getActivePane()

          expect(panes).toHaveLength 2
          expect(panes.indexOf(activePane)).toBe 1
          expect(getPaneOrientation(activePane)).toBe 'horizontal'
