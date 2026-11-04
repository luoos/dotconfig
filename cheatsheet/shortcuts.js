// Keyboard shortcuts shown by cheatsheet/index.html.
// This is the only file to edit when a config's keys change; the page and
// check.mjs read it. Run `node cheatsheet/check.mjs` afterwards.
//
// Each section: { app, title, file?, note?, items: [...] }
//   app   one of the APPS ids below (an array if it applies to several)
//   file  the config the "mine" items come from (repo-relative)
// Each item: { k, d, src?, tags? }
//   k     keys. Space = press one after another, '+' = hold together,
//         ' / ' separates alternatives, '_' is a space inside one key
//         (Mouse_drag), <name> is a placeholder you type, '…' is plain text.
//         'Prefix' = tmux prefix (Ctrl+b), 'Leader' = Space in Vim/Neovim.
//         Write a literal + as 'Plus'.
//   d     what it does
//   src   text that appears in `file` on the line that defines it (a string
//         or an array). Having src marks the item as set up in this repo
//         ("mine"); items without it are the tool's built-in defaults.
//   tags  extra search words

window.APPS = [
  { id: 'ghostty', name: 'Ghostty' },
  { id: 'tmux', name: 'tmux' },
  { id: 'zsh', name: 'zsh' },
  { id: 'nvim', name: 'Neovim' },
  { id: 'vim', name: 'Vim' },
];

window.SECTIONS = [
  // ── Ghostty ────────────────────────────────────────────────────────────
  {
    app: 'ghostty', title: 'Splits', file: 'ghostty/.config/ghostty/config.ghostty',
    items: [
      { k: 'Cmd+d', d: 'Split right', src: 'cmd+d=new_split:right', tags: 'vertical new pane' },
      { k: 'Cmd+Shift+d', d: 'Split down', src: 'cmd+shift+d=new_split:down', tags: 'horizontal new pane' },
      { k: 'Cmd+Shift+Left / Cmd+Shift+Right / Cmd+Shift+Up / Cmd+Shift+Down', d: 'Go to split in that direction', src: ['goto_split:left', 'goto_split:right', 'goto_split:up', 'goto_split:down'], tags: 'move focus pane arrow' },
      { k: 'Cmd+Shift+Enter', d: 'Zoom / unzoom split', src: 'toggle_split_zoom', tags: 'maximize fullscreen pane' },
      { k: 'Cmd+[ / Cmd+]', d: 'Previous / next split' },
      { k: 'Cmd+Ctrl+Left / Cmd+Ctrl+Right', d: 'Resize split (any arrow)' },
      { k: 'Cmd+Ctrl+=', d: 'Make splits equal size', tags: 'equalize' },
      { k: 'Cmd+w', d: 'Close split / tab', tags: 'quit surface' },
    ],
  },
  {
    app: 'ghostty', title: 'Tabs & windows', file: 'ghostty/.config/ghostty/config.ghostty',
    items: [
      { k: 'Cmd+t', d: 'New tab' },
      { k: 'Cmd+Shift+[ / Cmd+Shift+]', d: 'Previous / next tab', tags: 'switch' },
      { k: 'Cmd+1 … Cmd+8', d: 'Go to tab 1–8 (Cmd+9: last tab)' },
      { k: 'Cmd+n', d: 'New window' },
      { k: 'Cmd+Enter', d: 'Toggle fullscreen' },
      { k: 'Ctrl+`', d: 'Quick terminal (drop-down, from any app)', src: 'toggle_quick_terminal', tags: 'grave backtick global dropdown quake' },
    ],
  },
  {
    app: 'ghostty', title: 'Text, search & config', file: 'ghostty/.config/ghostty/config.ghostty',
    items: [
      { k: 'Shift+Enter', d: 'Insert newline (Claude Code and other TUIs)', src: 'shift+enter=text:\\n', tags: 'multiline' },
      { k: 'Cmd+f', d: 'Search scrollback (Cmd+g / Cmd+Shift+g: next / previous)', tags: 'find' },
      { k: 'Cmd+k', d: 'Clear screen' },
      { k: 'Cmd+Up / Cmd+Down', d: 'Jump to previous / next prompt', tags: 'scroll command' },
      { k: 'Cmd+Home / Cmd+End', d: 'Scroll to top / bottom' },
      { k: 'Cmd+= / Cmd+- / Cmd+0', d: 'Font bigger / smaller / reset', tags: 'zoom size' },
      { k: 'Cmd+Shift+p', d: 'Command palette' },
      { k: 'Cmd+,', d: 'Open config' },
      { k: 'Cmd+Shift+,', d: 'Reload config', tags: 'refresh' },
      { k: 'Opt', d: 'Acts as Alt / Meta (word jumps, Neovim Alt+j/k)', src: 'macos-option-as-alt = true', tags: 'option alt meta' },
      { k: 'Mouse_select', d: 'Copies to the clipboard automatically', src: 'copy-on-select = clipboard', tags: 'mouse copy' },
    ],
  },

  // ── tmux ───────────────────────────────────────────────────────────────
  {
    app: 'tmux', title: 'Sessions', file: 'zsh/.zshrc',
    note: 'Prefix is Ctrl+b. Press it, let go, then the key.',
    items: [
      { k: 't', d: 'Shell: attach to latest session, or create "main"', src: 't() {', tags: 'command attach start' },
      { k: 't <name>', d: 'Shell: attach / create / switch to session <name>', src: 'tmux switch-client -t', tags: 'command attach new' },
      { k: 'tl', d: 'Shell: list sessions', src: "alias tl='tmux ls'", tags: 'command ls' },
      { k: 'Prefix d', d: 'Detach' },
      { k: 'Prefix s', d: 'Choose session from a list', tags: 'switch tree' },
      { k: 'Prefix $', d: 'Rename session' },
      { k: 'Prefix ( / Prefix )', d: 'Previous / next session' },
    ],
  },
  {
    app: 'tmux', title: 'Windows', file: 'tmux/.tmux.conf',
    items: [
      { k: 'Prefix c', d: 'New window (in current directory)', src: 'bind c new-window', tags: 'tab create' },
      { k: 'Prefix n / Prefix p', d: 'Next / previous window' },
      { k: 'Prefix 1 … Prefix 9', d: 'Go to window by number (starts at 1)', src: 'set -g base-index 1' },
      { k: 'Prefix w', d: 'Choose window from a list' },
      { k: 'Prefix ,', d: 'Rename window' },
      { k: 'Prefix &', d: 'Kill window', tags: 'close' },
    ],
  },
  {
    app: 'tmux', title: 'Panes', file: 'tmux/.tmux.conf',
    items: [
      { k: 'Prefix |', d: 'Split left / right (current directory)', src: 'bind | split-window', tags: 'vertical pipe' },
      { k: 'Prefix -', d: 'Split top / bottom (current directory)', src: 'bind - split-window', tags: 'horizontal dash' },
      { k: 'Ctrl+h / Ctrl+j / Ctrl+k / Ctrl+l', d: 'Move between panes and Neovim windows (no prefix)', src: ['bind -n C-h', 'bind -n C-j', 'bind -n C-k', 'bind -n C-l', 'copy-mode-vi C-h', 'copy-mode-vi C-j', 'copy-mode-vi C-k', 'copy-mode-vi C-l'], tags: 'navigate focus vim-tmux-navigator' },
      { k: 'Prefix h / Prefix j / Prefix k / Prefix l', d: 'Select pane left / down / up / right (l replaces "last window")', src: ['bind h select-pane', 'bind j select-pane', 'bind k select-pane', 'bind l select-pane'], tags: 'navigate focus' },
      { k: 'Prefix H / Prefix J / Prefix K / Prefix L', d: 'Resize pane by 5 (repeatable)', src: ['bind -r H', 'bind -r J', 'bind -r K', 'bind -r L'] },
      { k: 'Prefix z', d: 'Zoom / unzoom pane', tags: 'maximize fullscreen' },
      { k: 'Prefix x', d: 'Kill pane', tags: 'close' },
      { k: 'Prefix q', d: 'Show pane numbers (press one to jump)' },
      { k: 'Prefix Space', d: 'Cycle layouts' },
      { k: 'Prefix { / Prefix }', d: 'Swap pane with previous / next' },
      { k: 'Prefix !', d: 'Break pane out into its own window' },
      { k: 'Prefix Ctrl+l', d: 'Clear screen (Ctrl+l alone moves pane)', src: 'bind C-l send-keys C-l', tags: 'clear' },
      { k: 'Mouse', d: 'Click to focus, drag border to resize, wheel to scroll', src: 'set -g mouse on' },
    ],
  },
  {
    app: 'tmux', title: 'Copy mode (vi keys)', file: 'tmux/.tmux.conf',
    items: [
      { k: 'PageUp', d: 'Scroll back without prefix (fn+Up on a Mac)', src: 'bind -n PageUp', tags: 'scroll history' },
      { k: 'Prefix v / Prefix [', d: 'Enter copy mode', src: 'bind v copy-mode', tags: 'scroll' },
      { k: 'v', d: 'Start selection', src: 'copy-mode-vi v send -X begin-selection' },
      { k: 'Ctrl+v', d: 'Toggle rectangle selection', src: 'rectangle-toggle', tags: 'block column' },
      { k: 'y', d: 'Copy to clipboard and exit (works over SSH)', src: 'copy-mode-vi y send', tags: 'yank osc52' },
      { k: 'Mouse_drag', d: 'Select and copy to clipboard', src: 'MouseDragEnd1Pane' },
      { k: '/ / ?', d: 'Search down / up (n / N: next / previous)', tags: 'find' },
      { k: 'q', d: 'Exit copy mode', tags: 'quit escape' },
    ],
  },
  {
    app: 'tmux', title: 'Misc', file: 'tmux/.tmux.conf',
    items: [
      { k: 'Prefix r', d: 'Reload ~/.tmux.conf', src: 'bind r source-file', tags: 'refresh config' },
      { k: 'Prefix ?', d: 'List all key bindings', tags: 'help' },
      { k: 'Prefix :', d: 'Command prompt' },
      { k: 'Prefix Ctrl+b', d: 'Send prefix to nested tmux (e.g. over SSH)', tags: 'nested remote ssh' },
    ],
  },

  // ── zsh ────────────────────────────────────────────────────────────────
  {
    app: 'zsh', title: 'Command line (vi mode)', file: 'zsh/.zshrc',
    note: 'Starts in insert mode (beam cursor). Esc switches to normal mode (block cursor).',
    items: [
      { k: 'Esc', d: 'Normal mode: vi motions on the command line', src: 'bindkey -v', tags: 'vi vim' },
      { k: 'v', d: '(normal mode) Edit command in Neovim', src: "bindkey -M vicmd 'v'", tags: 'editor' },
      { k: 'Up / Down', d: 'History matching what is typed so far', src: ["bindkey -M viins '^[[A'", "bindkey -M viins '^[[B'"], tags: 'previous prefix search' },
      { k: 'k / j', d: '(normal mode) Same history search', src: ["bindkey -M vicmd 'k'", "bindkey -M vicmd 'j'"] },
      { k: 'Ctrl+r', d: 'Search history backwards', src: "'^R'", tags: 'reverse find' },
      { k: 'Ctrl+a / Ctrl+e', d: 'Start / end of line', src: ["'^A'", "'^E'"], tags: 'home end beginning' },
      { k: 'Ctrl+w', d: 'Delete word before cursor', src: "'^W'", tags: 'kill' },
      { k: 'Backspace / Ctrl+h', d: 'Delete char (even before insert point)', src: ["'^?'", "'^H'"] },
      { k: 'Opt+Left / Opt+Right', d: 'Move by word (Ghostty Opt = Alt)', tags: 'jump' },
      { k: 'Tab', d: 'Complete' },
      { k: 'Ctrl+l', d: 'Clear screen' },
      { k: 'Ctrl+c', d: 'Cancel line / interrupt' },
    ],
  },

  // ── Neovim ─────────────────────────────────────────────────────────────
  {
    app: 'nvim', title: 'Windows & tmux', file: 'nvim/.config/nvim/init.lua',
    items: [
      { k: 'Ctrl+h / Ctrl+j / Ctrl+k / Ctrl+l', d: 'Move between windows, on into tmux panes', src: ["'<C-h>', '<cmd>TmuxNavigateLeft", "'<C-j>'", "'<C-k>'", "'<C-l>'"], tags: 'navigate focus split' },
      { k: 'Ctrl+h', d: '(terminal mode) Jump to window on the left', src: "map('t', '<C-h>'", tags: 'claude panel' },
      { k: 'Ctrl+\\ Ctrl+n', d: 'Leave terminal mode (to scroll / copy)', tags: 'escape normal' },
      { k: 'Leader z / Alt+z', d: 'Zoom window full-screen / restore layout. Alt+z also works in the Claude panel', src: ["'<leader>z', zoom", "'<M-z>', zoom"], tags: 'maximize fullscreen toggle terminal' },
      { k: 'Ctrl+w | / Ctrl+w _', d: 'Maximize window width / height', tags: 'maximize resize' },
      { k: 'Ctrl+w =', d: 'Make windows equal size (skips fixed-width splits like the Claude panel)', tags: 'reset resize equalize' },
      { k: 'Ctrl+w s / Ctrl+w v', d: 'Split below / right', tags: 'horizontal vertical' },
      { k: 'Ctrl+w q', d: 'Close window' },
      { k: 'Ctrl+w o', d: 'Close all other windows', tags: 'only' },
    ],
  },
  {
    app: 'nvim', title: 'Find (snacks picker)', file: 'nvim/.config/nvim/init.lua',
    items: [
      { k: 'Leader Leader / Leader f f', d: 'Find files (includes dotfiles)', src: ["'<leader><leader>'", "'<leader>ff'"], tags: 'open search fuzzy' },
      { k: 'Leader f g', d: 'Grep in project', src: "'<leader>fg'", tags: 'search text ripgrep' },
      { k: 'Leader f w', d: 'Grep word under cursor / selection', src: "'<leader>fw'" },
      { k: 'Leader f b', d: 'Open buffers', src: "'<leader>fb'" },
      { k: 'Leader f r', d: 'Recent files', src: "'<leader>fr'", tags: 'history' },
      { k: 'Leader f h', d: 'Search help', src: "'<leader>fh'" },
      { k: 'Alt+h / Alt+i', d: '(in picker) Toggle hidden / ignored files', src: 'Alt+h / Alt+i' },
    ],
  },
  {
    app: 'nvim', title: 'Claude Code', file: 'nvim/.config/nvim/init.lua',
    items: [
      { k: 'Leader a c', d: 'Toggle Claude panel', src: "'<leader>ac'", tags: 'ai open' },
      { k: 'Leader a f', d: 'Focus Claude panel', src: "'<leader>af'" },
      { k: 'Leader a r', d: 'Resume a conversation', src: "'<leader>ar'" },
      { k: 'Leader a C', d: 'Continue last conversation', src: "'<leader>aC'" },
      { k: 'Leader a b', d: 'Add current file to context', src: "'<leader>ab'", tags: 'buffer' },
      { k: 'Leader a s', d: 'Send current line / selection', src: "'<leader>as'" },
      { k: 'Leader a a / Leader a d', d: 'Accept / deny proposed diff', src: ["'<leader>aa'", "'<leader>ad'"] },
      { k: 'Leader a y', d: 'Copy "@file#L12" (or range) for any agent', src: "'<leader>ay'", tags: 'reference line path clipboard' },
    ],
  },
  {
    app: 'nvim', title: 'Code (LSP)', file: 'nvim/.config/nvim/init.lua',
    note: 'Install a language server with :Mason.',
    items: [
      { k: 'g d', d: 'Go to definition', src: "'gd', vim.lsp.buf.definition", tags: 'jump' },
      { k: 'g D', d: 'Go to declaration', src: "'gD'" },
      { k: 'g y', d: 'Go to type definition', src: "'gy'" },
      { k: 'K', d: 'Hover docs', tags: 'documentation' },
      { k: 'g r n', d: 'Rename symbol' },
      { k: 'g r a', d: 'Code action', tags: 'fix quickfix' },
      { k: 'g r r', d: 'References', tags: 'usages' },
      { k: 'g r i', d: 'Implementation' },
      { k: 'Ctrl+s', d: '(insert) Signature help', tags: 'parameters' },
      { k: '[ d / ] d', d: 'Previous / next diagnostic', tags: 'error warning' },
      { k: 'Ctrl+w d', d: 'Show diagnostic under cursor', tags: 'error float' },
    ],
  },
  {
    app: 'nvim', title: 'Editing extras', file: 'nvim/.config/nvim/init.lua',
    items: [
      { k: 'Alt+j / Alt+k', d: 'Move line / selection down / up', src: ["'<M-j>'", "'<M-k>'"], tags: 'swap' },
      { k: 'Esc', d: 'Clear search highlight', src: "'<Esc>', '<cmd>nohlsearch" },
      { k: 'g c c / g c', d: 'Comment line / selection or motion', tags: 'toggle' },
      { k: 'Leader m p', d: 'Markdown preview in browser (Markdown files)', src: "'<leader>mp'" },
      { k: 'Leader', d: 'Wait a moment: which-key lists what comes next', src: "require('which-key').setup", tags: 'help popup space' },
    ],
  },

  // ── Vim + Neovim basics ────────────────────────────────────────────────
  {
    app: ['nvim', 'vim'], title: 'Motions (Vim & Neovim)',
    items: [
      { k: 'h j k l', d: 'Left / down / up / right' },
      { k: 'w / b / e', d: 'Next word / previous word / end of word' },
      { k: '0 / ^ / $', d: 'Line start / first character / line end' },
      { k: 'g g / G', d: 'First / last line (12G: line 12)', tags: 'top bottom' },
      { k: 'f x / t x', d: 'Jump to / before next "x" (; , repeat)', tags: 'find char' },
      { k: '%', d: 'Jump to matching bracket' },
      { k: 'Ctrl+d / Ctrl+u', d: 'Half page down / up (smooth in Neovim)', tags: 'scroll' },
      { k: 'z z', d: 'Center cursor line on screen' },
      { k: 'Ctrl+o / Ctrl+i', d: 'Jump back / forward', tags: 'history jumplist' },
      { k: '* / #', d: 'Search word under cursor forward / back' },
      { k: '/text / ?text', d: 'Search forward / back (n / N: next / previous)', tags: 'find' },
    ],
  },
  {
    app: ['nvim', 'vim'], title: 'Editing (Vim & Neovim)',
    items: [
      { k: 'i / a', d: 'Insert before / after cursor' },
      { k: 'I / A', d: 'Insert at line start / end' },
      { k: 'o / O', d: 'New line below / above' },
      { k: 'v / V / Ctrl+v', d: 'Visual: chars / lines / block', tags: 'select' },
      { k: 'd d / y y / p', d: 'Delete line / yank line / paste (system clipboard)', tags: 'cut copy' },
      { k: 'c i w', d: 'Change inner word (also di", ya), ci( …)', tags: 'text object' },
      { k: 'u / Ctrl+r', d: 'Undo / redo (persists after closing)', tags: 'undofile' },
      { k: '.', d: 'Repeat last change' },
      { k: '> > / < <', d: 'Indent / outdent line' },
      { k: ':%s/a/b/g', d: 'Replace all "a" with "b"', tags: 'substitute find' },
      { k: ':w / :q / :wq', d: 'Save / quit / save and quit' },
    ],
  },

  // ── Vim ────────────────────────────────────────────────────────────────
  {
    app: 'vim', title: 'Vim only', file: 'vim/.vimrc',
    items: [
      { k: 'Leader a', d: 'Copy "@file#L12" (or range) for any agent', src: ['nnoremap <silent> <leader>a', 'xnoremap <silent> <leader>a'], tags: 'reference line path clipboard claude' },
      { k: 'Ctrl+l', d: 'Redraw and clear search highlight', src: 'nnoremap <silent> <C-l>' },
    ],
  },
];
