# open-this [![Build Status](https://travis-ci.org/t9md/atom-open-this.svg)](https://travis-ci.org/t9md/atom-open-this)

Open file under cursor.  
Like `gf` on Vim, `C-x C-f` on Emacs.

![gif](https://raw.githubusercontent.com/t9md/t9md/27a8b5d0b7dc4e080e615467e0daf3727c991835/img/atom-open-this.gif)

# How to use.

1. Place cursor on filename in text like on `./styles-element` in following code.
2. Invoke `open-this:here` via command palette or keymap.
3. file `./styles-element` opened in current pane.

```coffeescript
StylesElement = require './styles-element'
StorageFolder = require './storage-folder'
```

# Keymap

No default keymap, copy and paste to your `keymap.cson` from following example.

* Normal user

```coffeescript
'atom-workspace atom-text-editor:not([mini])':
  'cmd-k f f': 'open-this:here'
  'cmd-k f d': 'open-this:split-down'
  'cmd-k f r': 'open-this:split-right'
```

* [vim-mode](https://atom.io/packages/vim-mode) user.

```coffeescript
'atom-text-editor.vim-mode.normal-mode':
  'g f':      'open-this:here'
  'ctrl-w f': 'open-this:split-down'
  'ctrl-w F': 'open-this:split-right'
```

* [vim-mode-plus](https://atom.io/packages/vim-mode-plus) user.

```coffeescript
'atom-text-editor.vim-mode-plus.normal-mode':
  'g f':      'open-this:here'
  'ctrl-w f': 'open-this:split-down'
  'ctrl-w F': 'open-this:split-right'
```
