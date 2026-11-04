# dotconfig

Stow packages for Ghostty, tmux, zsh, Neovim and Vim; see README.md.

## Keyboard cheatsheet must follow the configs

`cheatsheet/index.html` shows every shortcut set up here plus common built-in
ones. Its data is `cheatsheet/shortcuts.js` (format documented at the top of
that file); the HTML only renders it.

Whenever a change adds, removes or rebinds a key (tmux `bind`, Ghostty
`keybind`, zsh `bindkey`/aliases/functions, Neovim `map(`, Vim `*map`):

1. Update the matching item in `cheatsheet/shortcuts.js` in the same commit.
   Items defined in a config carry `src`: text from the defining line.
2. Run `node cheatsheet/check.mjs` and make it pass. It reports `STALE` items
   whose `src` no longer appears in the config, `VAGUE` ones whose `src`
   matches more than one line (name the mode, e.g. `map('n', '<C-j>'`),
   `MISSING` binding lines no item covers, `PREFIX` if the tmux prefix changed,
   and `DATA` / `KEYS` mistakes in shortcuts.js itself.
3. If a new package or config file has key bindings, add it to `BINDINGS` in
   `check.mjs` and a section (with `file`) in `shortcuts.js`.
