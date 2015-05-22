# open-this package

Open file under cursor.  
Like `gf` on Vim, `C-x C-f` on Emacs.


![A screenshot of your package](https://f.cloud.github.com/assets/69169/2290250/c35d867a-a017-11e3-86be-cd7c5bf3ff9b.gif)

# Features

* Open file under cursor on same pane(or spilt pane).
* Currently not search library search path. Supported only relative path from current editor's file path.

# How to use.

1. Place cursor over filename on source code like `./styles-element` in following code.
2. Invoke `open-this:here` via command palette or keymap.
3. file `./styles-element` opend on same pane.

```coffeescript
StylesElement = require './styles-element'
StorageFolder = require './storage-folder'
```

# Keymap

No keymap by default.

e.g.

```coffeescript
'atom-workspace atom-text-editor:not([mini])':
  'cmd-k f f': 'open-this:here'
  'cmd-k f d': 'open-this:split-down'
  'cmd-k f r': 'open-this:split-right'
```

* if you are using  [vim-mode](https://atom.io/packages/vim-mode), following are suggestion which I use.

```coffeescript
'atom-text-editor.vim-mode.command-mode':
  'g f':      'open-this:here'
  'ctrl-w f': 'open-this:split-down'
  'ctrl-w F': 'open-this:split-right'
```

# TODO
- [ ] Precise language specifc filname and extname determination.
