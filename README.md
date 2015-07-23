# open-this

Open file under cursor.  
Like `gf` on Vim, `C-x C-f` on Emacs.

![gif](https://raw.githubusercontent.com/t9md/t9md/6b2b3a97f1309cab5d460358e4f148da7a6714ac/img/atom-open-this.gif)

# Features

* Open file under cursor on same pane(or spilt pane).
* Currently not search library search path. Supported only relative path from current editor's file path.

# How to use.

1. Place cursor over filename on source code like `./styles-element` in following code.
2. Invoke `open-this:here` via command palette or keymap.
3. file `./styles-element` opened on same pane.

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
'atom-text-editor.vim-mode.normal-mode':
  'g f':      'open-this:here'
  'ctrl-w f': 'open-this:split-down'
  'ctrl-w F': 'open-this:split-right'
```

# Helper package

* [goto-scope](https://atom.io/packages/goto-scope)

Now you can now file under cursor by this package.  
But you still need to move cursor to string containing filename.  
Fortunately, filename have always have string scope information on Atom(you can see by `editor:log-cursor-scope` command).  
goto-scope helps you to move cursor by using scope information.
You can put cursor to next/prev string scope.

## Expample

```coffeescript
'atom-text-editor.vim-mode.command-mode':
  "s": 'goto-scope:string-next',
```

And set goto-scope's `offsetString` to 3.

By this seting you can move curor position `from` to `to` with one `s` key.  
Then you can use `gf` to open file.

```coffeescript
# from                     to
#  v                       v
StylesElement = require './styles-element'
```

# TODO
- [ ] Library load path based on language?
