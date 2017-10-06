## 0.5.0
- New: #13 Open `index.jsx` if there is no `index.js` by iammerrick
- Maintenance: Convert CoffeeScript to JavaScript.

## 0.4.0
- In CoffeeScript and JavaScript file, open `index.js` if filePath found was directory.

## 0.3.0
- New: Support sass's partial file which starts `_`(e.g. `_partial.scss`) #6 by @admosity

## 0.2.0
- New: Open specific line and column when filename have `:line:column` suffix by @djui

## 0.1.9
- New: Search from project root dir suggested by @bronson #2.

## 0.1.8
- Support git-diff style file string(try to open by removing a/, b/ part) suggested by @bwinton.

## 0.1.7 - fix
- Deprecation warning fix from Atom v1.1.0

## 0.1.6 - Minor improve
- Add spec
- Refactoring

## 0.1.5 - Doc
- Update readme to follow vim-mode's rename from command-mode to normal-mode

## 0.1.4 - Improve
* Now detect file with different extension if basename is same.

## 0.1.3 - Improve
* Detect filename by appending extensions from `Grammar::fileTypes` list.

## 0.1.2 - Improve
* Improve file path determination strategy
# lib
## 0.1.1 - Doc update
* Add gif

## 0.1.0 - First Release
* Inital release
