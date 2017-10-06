const path = require("path")
const fs = require("fs-plus")

const FILENAME_WITH_LOCATION_REGEX = /[-\w/\.]+(:\d+){0,2}/g

function hasCommonJSPackageSemantics(scopeName) {
  // why use `startsWith` is to make `source.js.jsx` true.
  return scopeName.startsWith("source.js") || scopeName.startsWith("source.coffee")
}

function getBaseName(file) {
  return path.basename(file, path.extname(file))
}

function uniq(list) {
  return list.reduce((acc, cur) => (acc.indexOf(cur) === -1 ? acc.concat(cur) : acc), [])
}

module.exports = {
  activate(state) {
    this.disposable = atom.commands.add("atom-text-editor", {
      "open-this:here": () => this.open(),
      "open-this:split-down": () => this.open({split: "down"}),
      "open-this:split-right": () => this.open({split: "right"}),
    })
  },

  deactivate() {
    this.disposable.dispose()
  },

  getCandidateFiles(file) {
    const editor = atom.workspace.getActiveTextEditor()
    const currentExtension = (path.extname(editor.getURI()) || "").substr(1)
    const filesWithExtension = [currentExtension, ...(editor.getGrammar().fileTypes || [])]
      .filter(ext => ext) // filter falsy
      .map(ext => `${file}.${ext}`)
    return uniq([...filesWithExtension, file])
  },

  // Return first existing filePath in following order.
  //  - File with same extension to current file's
  //  - File with extensions... from current Grammar.fileTypes
  //  - File have same basename
  findOpenableFile(filePath) {
    // Search existing file from file list.
    const file = this.getCandidateFiles(filePath).find(f => fs.isFileSync(f))
    if (file) return file

    // Search file have same basename.
    const baseName = getBaseName(filePath)
    return fs.listSync(path.dirname(filePath)).find(f => getBaseName(f) === baseName && fs.isFileSync(f))
  },

  getFilePath(editor, fileName) {
    const dirName = path.dirname(editor.getURI())
    const {scopeName} = editor.getGrammar()

    const baseFilePath = path.resolve(dirName, fileName)
    if (fs.isDirectorySync(baseFilePath) && hasCommonJSPackageSemantics(scopeName)) {
      const extensions = [".js", ".coffee", ".jsx"]
      const indexFilePath = extensions
        .map(ext => path.join(baseFilePath, `index${ext}`))
        .find(indexFilePath => fs.isFileSync(indexFilePath))
      if (indexFilePath) return indexFilePath
    }

    const filePath = this.findOpenableFile(path.resolve(dirName, fileName))
    if (filePath) return filePath

    // If grammar was sass or scss try to find partial(starts with `_`).
    if (["source.sass", "source.css.scss"].includes(scopeName)) {
      const fragments = fileName.split(path.sep)
      const lastPart = fragments.pop()
      const sassPartialFileName = path.join(...fragments, "_" + lastPart)
      return this.findOpenableFile(path.resolve(dirName, sassPartialFileName))
    }

    // git diff output
    if (fileName.match(/^[ab]\//)) {
      return this.findOpenableFile(path.resolve(dirName, fileName.replace(/^[ab]\//, "")))
    }

    // Search from projectRoot
    for (const dir of atom.project.getPaths()) {
      if (dirName.startsWith(dir)) {
        return this.findOpenableFile(path.resolve(dir, fileName))
      }
    }
    return null
  },

  open({split} = {}) {
    const editor = atom.workspace.getActiveTextEditor()
    const cursorPosition = editor.getCursorBufferPosition()
    const scanRange = editor.bufferRangeForBufferRow(cursorPosition.row)

    let fileNameWithLocation
    editor.scanInBufferRange(FILENAME_WITH_LOCATION_REGEX, scanRange, event => {
      if (event.range.containsPoint(cursorPosition)) {
        fileNameWithLocation = event.matchText
        event.stop()
      }
    })
    if (!fileNameWithLocation) return

    const [fileName, line, column] = fileNameWithLocation.split(":")
    const filePath = this.getFilePath(editor, fileName)
    if (filePath) {
      const options = {searchAllPanes: false, split}
      if (line != null) options.initialLine = Number(line) - 1
      if (column != null) options.initialColumn = Number(column) - 1
      atom.workspace.open(filePath, options)
    }
  },
}
