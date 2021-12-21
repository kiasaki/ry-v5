# ry

_A basic modal text editor, written in Chicken Scheme_

### installing

To build and install `ry` on your computer simply run `chicken-install` from the
project's root directory.

### developing

```bash
$ make run 2> error.log # Build ry & runs it, redirecting error/debug to file
$ tail -f error.log # Stream error/debug info to standard out
$ make repl # Run a chicken scheme repl with history (backed by linenoise)
```

### features

`ry` is a text editor aiming to provide an editing environment similar to `vim`
in terms of key bindings while being as easily extended as `emacs`.

It is easy to extend in scheme, and, as emacs, the core being written in the same
language, you can change virtually everything in your plugins.

**Currently implemented keybindings:**

- Normal Mode
  - <kbd>q</kbd> Quits editor (`save-buffers-kill-ry`)
  - <kbd>i</kbd> Enters insert-mode (`enter-insert-mode`)
  - <kbd>a</kbd> Enters insert-mode moving right before
  - <kbd>A</kbd> Enters insert-mode moving to the end of the line
  - <kbd>0</kbd> Moves cursor to the beginning of the line (`beginning-of-line`)
  - <kbd>$</kbd> Moves cursor to the beginning of the line (`end-of-line`)
  - <kbd>^</kbd> Move to first non whitespace character of line (`first-non-whitespace`)
  - <kbd>w</kbd> Move to beginning of WORD forward (`next-beginning-of-word`)
  - <kbd>W</kbd> Move to beginning of WORD forward (`next-beginning-of-word`)
  - <kbd>b</kbd> Move to beginning of WORD backwards (`previous-beginning-of-word`)
  - <kbd>B</kbd> Move to beginning of WORD backwards (`previous-beginning-of-word`)
  - <kbd>o</kbd> Insert a new line below current line (`insert-line-up`)
  - <kbd>O</kbd> Insert a new line above current line (`insert-line-down`)
  - <kbd>h</kbd> Moves cursor left (`backward-char`)
  - <kbd>j</kbd> Moves cursor down (`next-line`)
  - <kbd>k</kbd> Moves cursor up (`previous-line`)
  - <kbd>l</kbd> Moves cursor right (`forward-char`)
  - <kbd>gg</kbd> Move to beginning of buffer (`beginning-of-buffer`)
  - <kbd>G</kbd> Move to end of buffer (`end-of-buffer`)
  - <kbd>ctrl</kbd>+<kbd>u</kbd> Jump 15 lines up (`previous-line-jump`)
  - <kbd>ctrl</kbd>+<kbd>d</kbd> Jump 15 lines down (`next-line-jump`)
  - <kbd>yy</kbd> Yanks current line to . register (`copy-whole-line`)
  - <kbd>p</kbd> Pastes contents of . register (`paste`)
  - <kbd>d</kbd><kbd>d</kbd> Deletes current line (`kill-whole-line`)
  - <kbd>d</kbd><kbd>h</kbd> or <kbd>d</kbd><kbd>j</kbd> Deletes char left of cursor  (`delete-backward-char`)
  - <kbd>d</kbd><kbd>k</kbd> or <kbd>d</kbd><kbd>l</kbd> Deletes char right of cursor  (`delete-forward-char`)
  - <kbd>:</kbd> Asks for a command in the minibuffer and eval's it (`smex`)
  - <kbd>:</kbd><kbd>q</kbd><kbd>Enter</kbd> Quits
  - <kbd>:</kbd><kbd>w</kbd><kbd>Enter</kbd> Saves current buffer
  - <kbd>x</kbd> Deletes char under cursor (`delete-char-under-cursor`)
  - <kbd>Ctrl</kbd>+<kbd>x</kbd> <kbd>Ctrl</kbd>+<kbd>f</kbd> Open file (`open-file`)
  - <kbd>Ctrl</kbd>+<kbd>x</kbd> <kbd>Ctrl</kbd>+<kbd>c</kbd> Quit (`kill-ry`)
  - <kbd>Ctrl</kbd>+<kbd>w</kbd> <kbd>s</kbd> Split window horizontally (`split-window-horizontally`)
  - <kbd>Ctrl</kbd>+<kbd>w</kbd> <kbd>v</kbd> Split window vertically (`split-window-vertically`)
  - <kbd>Ctrl</kbd>+<kbd>w</kbd> <kbd>h</kbd> Move to left window (`window-move-left`)
  - <kbd>Ctrl</kbd>+<kbd>w</kbd> <kbd>j</kbd> Move to bottom window (`window-move-bottom`)
  - <kbd>Ctrl</kbd>+<kbd>w</kbd> <kbd>k</kbd> Move to top window (`window-move-top`)
  - <kbd>Ctrl</kbd>+<kbd>w</kbd> <kbd>l</kbd> Move to right window (`window-move-right`)
- Insert mode
  - <kbd>any visible chars</kbd> Inserts character at cursor's position (`self-insert-char`)
  - <kbd>backspace</kbd> Deletes character to the left (`delete-backward-char`)
  - <kbd>esc</kbd> Enters normal mode  (`enter-normal-mode`)
- Command mode (when typing in the minibuffer)
  - <kbd>any visible chars</kbd> Inserts character at cursor's position (`command-mode-insert-char`)
  - <kbd>backspace</kbd> Deletes character to the left (`command-mode-delete-char`)
  - <kbd>enter</kbd> Commits command (sends command text to handler) (`command-mode-commit`)
  - <kbd>esc</kbd> Enters normal mode (`exit-command-mode`)

### other features

- Windows
- Basic auto-indent
- Basic showing of space characters at eol
- Buffers based editing (you can edit other files without the need to re-open previous)
- Basic yank-kill-paste with 27 registers (. & a-z)

### screenshot

![](https://raw.githubusercontent.com/kiasaki/scheme-ry/master/support/screenshot.png)

### todo (minimal usability)

- basic highlighting (only comments and [](){}""'')
- visual mode
  - support movement
  - visual line mode
  - support <kbd>d</kbd>
  - support <kbd>c</kbd>
  - support <kbd>y</kbd>
- support <kbd>~</kbd> (in visual too)
- support <kbd>gu</kbd> (in visual too)
- support <kbd>gU</kbd> (in visual too)
- support <kbd><</kbd> & <kbd>></kbd> (in visual too)
- <kbd>b</kbd> & <kbd>e</kbd> & <kbd>w</kbd>
- <kbd>[n]gg</kbd>
- change directory
- run shell command
- completion in opening file

### todo

- highlighting (syntax based)
- ~~better key mapping (support for ctrl & meta)~~
- <kbd>zz</kbd>
- kill-ring (with named registers)
- ~saving~
- searching `n N * / #`
- `f{char} & F{char}`
- undo/redo
- user config file
- themes
- dired
- completion in command mode
- configuration options
- hooks (enter mode, exit mode, new buffer, read buffer,...) a la aucmd

### license

See `LICENSE` file.
