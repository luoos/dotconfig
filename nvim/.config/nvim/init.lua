-- ~/.config/nvim/init.lua — Neovim 0.12+, plugins via the built-in vim.pack
-- Update plugins: :lua vim.pack.update()   Health check: :checkhealth

vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- ── Options ──────────────────────────────────────────────────────────────
local o = vim.opt
o.number = true
o.relativenumber = true
o.cursorline = true
o.signcolumn = 'yes'          -- keep git signs from shifting text
o.scrolloff = 5
o.mouse = 'a'
o.clipboard = 'unnamedplus'   -- yank/paste use the system clipboard
-- Over SSH there's no system clipboard: copy to the local one with OSC 52
-- (through tmux into Ghostty), and paste from Neovim's own register instead of
-- asking the terminal for its clipboard.
if vim.env.SSH_TTY then
  local osc52 = require('vim.ui.clipboard.osc52')
  local paste = function() return { vim.fn.split(vim.fn.getreg(''), '\n'), vim.fn.getregtype('') } end
  vim.g.clipboard = {
    name = 'OSC 52',
    copy = { ['+'] = osc52.copy('+'), ['*'] = osc52.copy('*') },
    paste = { ['+'] = paste, ['*'] = paste },
  }
end
o.expandtab = true
o.tabstop = 4
o.shiftwidth = 4
o.softtabstop = 4
o.smartindent = true
o.ignorecase = true
o.smartcase = true
o.undofile = true             -- undo history survives closing a file
o.splitright = true
o.splitbelow = true
o.updatetime = 250
o.confirm = true              -- ask instead of failing on :q with unsaved changes
o.completeopt = { 'menuone', 'noselect', 'fuzzy', 'popup' } -- don't auto-insert first match; enable fuzzy completion
-- Show completions as you type (Neovim 0.12): the language server first (via
-- omnifunc), then words in this buffer, other windows and open buffers.
-- Ctrl+n / Ctrl+p move through the menu, Ctrl+y accepts, Ctrl+e closes it.
o.autocomplete = true
o.complete = 'o,.,w,b'
-- ...but only in files, and only once a name is being typed: not on a fresh or
-- blank line, and not after a space. (After "." the language server still opens the menu.)
do
  local function char_before()
    local col = vim.fn.col('.') - 1
    return col > 0 and vim.fn.getline('.'):sub(col, col) or ''
  end
  -- Only in files: not in the picker's search box, prompts or other special buffers
  local is_word = function(c) return vim.bo.buftype == '' and c:match('[%w_]') ~= nil end
  local g = vim.api.nvim_create_augroup('autocomplete_after_typing', {})
  vim.api.nvim_create_autocmd('InsertEnter', { group = g, callback = function() o.autocomplete = false end })
  vim.api.nvim_create_autocmd('InsertCharPre', { group = g, callback = function() o.autocomplete = is_word(vim.v.char) end })
  vim.api.nvim_create_autocmd({ 'TextChangedI', 'TextChangedP' }, { group = g, callback = function()
    local c = char_before()
    o.autocomplete = is_word(c)
    if c:match('^%s?$') and vim.fn.pumvisible() == 1 then
      vim.api.nvim_feedkeys(vim.keycode('<C-e>'), 'n', false) -- backspaced to nothing: close it
    end
  end })
end

-- ── Colors ────────────────────────────────────────────────────────────────
o.termguicolors = true
o.background = 'light'

-- ── Keymaps ──────────────────────────────────────────────────────────────
local map = vim.keymap.set
map('n', '<Esc>', '<cmd>nohlsearch<CR>', { desc = 'Clear search highlight' })
-- Ctrl+h/j/k/l move between Neovim windows and, at the edge, on into tmux panes
-- (vim-tmux-navigator; ~/.tmux.conf has the matching half). Outside tmux they
-- just move between Neovim windows.
vim.g.tmux_navigator_no_mappings = 1
map('n', '<C-h>', '<cmd>TmuxNavigateLeft<CR>', { desc = 'Window/pane left' })
map('n', '<C-j>', '<cmd>TmuxNavigateDown<CR>', { desc = 'Window/pane down' })
map('n', '<C-k>', '<cmd>TmuxNavigateUp<CR>', { desc = 'Window/pane up' })
map('n', '<C-l>', '<cmd>TmuxNavigateRight<CR>', { desc = 'Window/pane right' })
-- From a terminal (e.g. the Claude panel on the right), Ctrl+h jumps back to the
-- window on the left. (Esc is left alone: Claude Code uses Esc Esc itself.)
map('t', '<C-h>', '<C-\\><C-n><cmd>TmuxNavigateLeft<CR>', { desc = 'Window/pane left' })
-- Ctrl+q leaves terminal mode (same as Ctrl+\ Ctrl+n) to scroll / copy the
-- output with Vim keys; i or a goes back to typing.
map('t', '<C-q>', '<C-\\><C-n>', { desc = 'Leave terminal mode (scroll / copy)' })
-- Ctrl+p / Alt+p: back to the previous window (Ctrl+w p), also from the Claude
-- panel (so programs in Neovim terminals don't get Ctrl+p). Landing in a
-- terminal starts typing there.
local function prev_win()
  if vim.api.nvim_get_mode().mode == 't' then vim.cmd.stopinsert() end
  vim.cmd.wincmd('p')
  if vim.bo.buftype == 'terminal' then vim.cmd.startinsert() end
end
map({ 'n', 't' }, '<C-p>', prev_win, { desc = 'Previous window' })
map({ 'n', 't' }, '<M-p>', prev_win, { desc = 'Previous window' })
-- Move lines with Alt+j/k (Option works as Alt in Ghostty)
map('n', '<M-j>', '<cmd>m .+1<CR>==', { desc = 'Move line down' })
map('n', '<M-k>', '<cmd>m .-2<CR>==', { desc = 'Move line up' })
map('x', '<M-j>', ":m '>+1<CR>gv=gv", { desc = 'Move selection down' })
map('x', '<M-k>', ":m '<-2<CR>gv=gv", { desc = 'Move selection up' })

-- Briefly highlight yanked text
vim.api.nvim_create_autocmd('TextYankPost', {
  callback = function() vim.hl.on_yank() end,
})

-- Copy "@path#L12" / "@path#L12-20" to the clipboard (for pasting into any agent)
local function line_ref(l1, l2)
  local path = vim.fn.expand('%:.')
  if path == '' then return vim.notify('Buffer has no file', vim.log.levels.WARN) end
  return '@' .. path .. '#L' .. l1 .. (l1 == l2 and '' or '-' .. l2)
end
local function copy_line_ref(l1, l2)
  local ref = line_ref(l1, l2)
  if not ref then return end
  vim.fn.setreg('+', ref .. ' ')
  vim.notify('Copied ' .. ref)
end
map('n', '<leader>ay', function() local l = vim.fn.line('.'); copy_line_ref(l, l) end,
  { desc = 'Copy @file#L ref' })
map('x', '<leader>ay', function()
  local a, b = vim.fn.line('v'), vim.fn.line('.')
  vim.api.nvim_feedkeys(vim.keycode('<Esc>'), 'n', false)
  copy_line_ref(math.min(a, b), math.max(a, b))
end, { desc = 'Copy @file#L ref' })

-- ── Plugins ──────────────────────────────────────────────────────────────
-- markdown-preview.nvim's page rewrites its address to /<bufnr>, which the server
-- doesn't serve, so reloading the browser tab gives a 404. Patch the built page to
-- keep /page/<bufnr> instead. Safe to run repeatedly.
local function patch_mkdp_reload(dir)
  local files = vim.fn.glob(dir .. '/app/out/_next/static/*/pages/index.js', false, true)
  for _, file in ipairs(files) do
    local text = table.concat(vim.fn.readfile(file, 'b'), '\n')
    local fixed, n = text:gsub('replaceState%(null,"","/"%.concat', 'replaceState(null,"","/page/".concat')
    if n > 0 then vim.fn.writefile(vim.split(fixed, '\n', { plain = true }), file, 'b') end
  end
end

-- Add Mason's bin directory to PATH so tools like tree-sitter and LSPs are accessible
local mason_bin = vim.fn.stdpath('data') .. '/mason/bin'
if not vim.env.PATH:find(mason_bin, 1, true) then
  vim.env.PATH = mason_bin .. ':' .. vim.env.PATH
end

-- markdown-preview.nvim needs its preview server binary; fetch it after install/update.
-- (Must be defined before vim.pack.add so it fires on first install.)
vim.api.nvim_create_autocmd('PackChanged', {
  callback = function(ev)
    local name, kind = ev.data.spec.name, ev.data.kind
    if name == 'markdown-preview.nvim' and (kind == 'install' or kind == 'update') then
      if not ev.data.active then vim.cmd.packadd('markdown-preview.nvim') end
      vim.fn['mkdp#util#install']()
      patch_mkdp_reload(ev.data.path)
    end
    if name == 'nvim-treesitter' and (kind == 'install' or kind == 'update') then
      if not ev.data.active then vim.cmd.packadd('nvim-treesitter') end
      pcall(vim.cmd, 'TSUpdate')
    end
  end,
})

vim.pack.add({
  'https://github.com/folke/snacks.nvim',        -- picker, terminal (used by claudecode)
  'https://github.com/coder/claudecode.nvim',    -- Claude Code integration, like Zed/VS Code
  'https://github.com/lewis6991/gitsigns.nvim',  -- git changes in the sign column
  'https://github.com/folke/which-key.nvim',     -- popup listing keymaps after <Space>
  'https://github.com/neovim/nvim-lspconfig',    -- ready-made language server configs
  'https://github.com/mason-org/mason.nvim',     -- :Mason installs language servers
  'https://github.com/mason-org/mason-lspconfig.nvim', -- enables servers Mason installed
  'https://github.com/christoomey/vim-tmux-navigator', -- Ctrl+h/j/k/l across Neovim and tmux
  'https://github.com/iamcco/markdown-preview.nvim',   -- live Markdown preview in the browser
  'https://github.com/stevearc/conform.nvim',    -- Space c f formats with ruff etc.
  { src = 'https://github.com/catppuccin/nvim', name = 'catppuccin' },
  'https://github.com/nvim-treesitter/nvim-treesitter',
}, { confirm = false })

-- ── Theme: Catppuccin ─────────────────────────────────────────────────────
local catppuccin_ok, catppuccin = pcall(require, 'catppuccin')
if catppuccin_ok then
  catppuccin.setup({
    flavour = 'latte', -- latte (light), frappe, macchiato, mocha (dark)
    background = {
      light = 'latte',
      dark = 'mocha',
    },
    integrations = {
      treesitter = true,
      gitsigns = true,
      which_key = true,
      snacks = true,
      mason = true,
    },
  })
  vim.cmd.colorscheme('catppuccin')
else
  vim.cmd.colorscheme('default')
end

-- ── Tree-sitter (enhanced syntax highlighting) ───────────────────────────
local ts_ok, ts = pcall(require, 'nvim-treesitter')
if ts_ok then
  ts.setup()
  -- Neovim 0.12 native Tree-sitter highlighting
  vim.api.nvim_create_autocmd('FileType', {
    callback = function()
      pcall(vim.treesitter.start)
    end,
  })
end

require('snacks').setup({
  -- Include dotfiles (.zshrc, .config/...) in file search and grep; .git and
  -- gitignored files stay out. In the picker, Alt+h / Alt+i toggle these.
  picker = {
    enabled = true,
    sources = { files = { hidden = true }, grep = { hidden = true } },
    win = {
      list = {
        keys = {
          ['w'] = { { 'pick_win', 'jump' }, desc = 'Pick window' },
          ['v'] = { 'edit_vsplit', desc = 'Split vertical' },
          ['s'] = { 'edit_split', desc = 'Split horizontal' },
        },
      },
    },
  },
  terminal = { enabled = true },
  input = { enabled = true },
  -- Smooth scrolling for Ctrl+d/u/f/b, the mouse wheel, gg/G, zz, etc.
  -- 150ms per jump, fast start then easing out; holding a key speeds up.
  scroll = {
    enabled = true,
    animate = { duration = { step = 10, total = 150 }, easing = 'outQuad' },
  },
})
require('gitsigns').setup()
require('which-key').setup({ delay = 300 })
require('which-key').add({
  { '<leader>a', group = 'AI (Claude, Antigravity)' },
  { '<leader>c', group = 'Code' },
  { '<leader>f', group = 'Find' },
  { '<leader>g', group = 'Git' },
})

-- ── Language servers (go to definition, completion, diagnostics) ─────────
-- Install a server with :Mason (or :MasonInstall pyright); it's enabled automatically.
-- Neovim's built-in LSP keys: K hover, grn rename, gra code action, grr references,
-- gri implementation, Ctrl+] definition, Ctrl+s signature help (insert mode).
require('mason').setup()
require('mason-lspconfig').setup()
vim.lsp.config('lua_ls', { settings = { Lua = { diagnostics = { globals = { 'vim', 'Snacks' } } } } })
vim.lsp.config('pyright', {
  settings = {
    python = {
      analysis = {
        typeCheckingMode = 'off',
        autoSearchPaths = true,
        useLibraryCodeForTypes = true,
        diagnosticMode = 'openFilesOnly',
      },
    },
  },
})
vim.diagnostic.config({ virtual_text = true })
vim.api.nvim_create_autocmd('LspAttach', {
  callback = function(ev)
    local client = vim.lsp.get_client_by_id(ev.data.client_id)
    local opts = function(desc) return { buffer = ev.buf, desc = desc } end
    map('n', 'gd', vim.lsp.buf.definition, opts('Go to definition'))
    map('n', 'gD', vim.lsp.buf.declaration, opts('Go to declaration'))
    map('n', 'gy', vim.lsp.buf.type_definition, opts('Go to type definition'))
    if client and client:supports_method('textDocument/completion') then
      vim.lsp.completion.enable(true, client.id, ev.buf, { autotrigger = true })
    end
  end,
})

-- ── Formatting (conform.nvim): Space c f ──────────────────────────────────
-- Python: ruff sorts imports, then formats (wraps code at 80 columns, strips
-- trailing spaces, collapses extra blank lines). Install with :MasonInstall ruff.
-- A project's own ruff.toml / [tool.ruff] wins over the 80-column default.
-- Other files: the language server's formatter if it has one, else just trim
-- trailing spaces and blank lines at the end.
local function ruff_line_length(_, ctx)
  local found = vim.fs.find({ 'ruff.toml', '.ruff.toml', 'pyproject.toml' }, { upward = true, path = ctx.dirname })
  for _, f in ipairs(found) do
    if not f:match('pyproject%.toml$') then return {} end
    local ok, lines = pcall(vim.fn.readfile, f)
    if ok and table.concat(lines, '\n'):find('[tool.ruff', 1, true) then return {} end
  end
  return { '--line-length', '80' }
end
require('conform').setup({
  formatters_by_ft = {
    python = { 'ruff_organize_imports', 'ruff_format' },
    ['_'] = { 'trim_whitespace', 'trim_newlines', lsp_format = 'prefer' },
  },
  formatters = {
    ruff_organize_imports = { append_args = ruff_line_length },
    ruff_format = { append_args = ruff_line_length },
  },
})
map({ 'n', 'x' }, '<leader>cf', function() require('conform').format({ async = true }) end,
  { desc = 'Format file (or selection)' })

-- Finding things (snacks picker)
local pick = function(name) return function() Snacks.picker[name]() end end
local function toggle_explorer()
  local explorer = Snacks.picker.get({ source = 'explorer' })[1]
  if explorer then
    explorer:close()
  else
    Snacks.explorer()
  end
end
map('n', '<leader>e', toggle_explorer, { desc = 'Toggle file explorer sidebar' })
map('n', '<leader>fe', toggle_explorer, { desc = 'Toggle file explorer sidebar' })
map('n', '<leader><leader>', pick('files'), { desc = 'Find files' })
map('n', '<leader>ff', pick('files'), { desc = 'Files' })
map('n', '<leader>fg', pick('grep'), { desc = 'Grep' })
map('n', '<leader>fb', pick('buffers'), { desc = 'Buffers' })
map('n', '<leader>fr', pick('recent'), { desc = 'Recent files' })
map('n', '<leader>fh', pick('help'), { desc = 'Help' })
map({ 'n', 'x' }, '<leader>fw', pick('grep_word'), { desc = 'Word under cursor' })

-- Zoom: show the current window full-screen; press again to restore the layout
-- (like tmux's Prefix z). Unlike Ctrl+w = it isn't stopped by fixed-width splits.
-- Alt+z does the same and also works inside terminals (the Claude panel), where
-- Space is typed as text. A terminal stays in terminal mode after zooming.
local function zoom()
  local term = vim.api.nvim_get_mode().mode == 't'
  Snacks.zen.zoom()
  if term and vim.bo.buftype == 'terminal' then vim.cmd.startinsert() end
end
map('n', '<leader>z', zoom, { desc = 'Zoom window (toggle)' })
map({ 'n', 't' }, '<M-z>', zoom, { desc = 'Zoom window (toggle)' })

-- Git: whole project in the snacks picker (Tab stages, Ctrl+r discards), and the
-- change under the cursor with gitsigns
local gs = require('gitsigns')
map('n', '<leader>gs', pick('git_status'), { desc = 'Status (Tab stages)' })
map('n', '<leader>gd', pick('git_diff'), { desc = 'All changes' })
map('n', '<leader>gl', pick('git_log_file'), { desc = 'File history' })
map('n', '<leader>gD', gs.diffthis, { desc = 'Diff this file (side by side)' })
map('n', ']h', function() gs.nav_hunk('next') end, { desc = 'Next change' })
map('n', '[h', function() gs.nav_hunk('prev') end, { desc = 'Previous change' })
map('n', '<leader>gp', gs.preview_hunk_inline, { desc = 'Preview change' })
map('n', '<leader>gS', gs.stage_hunk, { desc = 'Stage / unstage change' })
map('n', '<leader>gr', gs.reset_hunk, { desc = 'Reset change' })
map('n', '<leader>gb', gs.blame_line, { desc = 'Blame line' })

-- Markdown preview in the browser (follows the cursor; only in Markdown buffers)
vim.api.nvim_create_autocmd('FileType', {
  pattern = 'markdown',
  callback = function(ev)
    map('n', '<leader>mp', '<cmd>MarkdownPreviewToggle<CR>', { buffer = ev.buf, desc = 'Markdown preview' })
    -- The plugin only refreshes on cursor movement, so edits that leave the cursor
    -- in place (x, u, p, .) or a reload after an outside change go unnoticed.
    -- A no-op while the preview is closed.
    vim.api.nvim_create_autocmd({ 'TextChanged', 'TextChangedI', 'FileChangedShellPost' }, {
      buffer = ev.buf,
      callback = function() vim.fn['mkdp#rpc#preview_refresh']() end,
    })
  end,
})

-- Reload files changed outside Neovim (e.g. by Claude Code in another split)
-- when coming back to Neovim or pausing; 'autoread' is on by default.
vim.api.nvim_create_autocmd({ 'FocusGained', 'BufEnter', 'CursorHold' }, {
  callback = function()
    if vim.fn.getcmdwintype() == '' then vim.cmd('silent! checktime') end
  end,
})

-- Claude Code. Either open it inside Neovim (<Space>ac), or run `claude` in another
-- Ghostty split and type /ide there to connect to this Neovim.
require('claudecode').setup()
map('n', '<leader>ac', '<cmd>ClaudeCode<CR>', { desc = 'Toggle Claude' })
map('n', '<leader>af', '<cmd>ClaudeCodeFocus<CR>', { desc = 'Focus Claude' })
map('n', '<leader>ar', '<cmd>ClaudeCode --resume<CR>', { desc = 'Resume conversation' })
map('n', '<leader>aC', '<cmd>ClaudeCode --continue<CR>', { desc = 'Continue last conversation' })
map('n', '<leader>ab', '<cmd>ClaudeCodeAdd %<CR>', { desc = 'Add current file' })
map('n', '<leader>aa', '<cmd>ClaudeCodeDiffAccept<CR>', { desc = 'Accept diff' })
map('n', '<leader>ad', '<cmd>ClaudeCodeDiffDeny<CR>', { desc = 'Deny diff' })

-- Antigravity CLI (`agy`) in a right-hand terminal panel, like Claude's. It has no
-- Neovim link: type @file yourself (Space a y copies one), and its edits land on
-- disk and reload here. Install: curl -fsSL https://antigravity.google/cli/install.sh | bash
local agy_panel
local function antigravity(args)
  return function()
    if agy_panel and agy_panel:buf_valid() then return agy_panel:toggle() end
    if vim.fn.executable('agy') == 0 then
      return vim.notify('Antigravity CLI (agy) is not installed. See init.lua for the install line.', vim.log.levels.WARN)
    end
    agy_panel = Snacks.terminal.open(vim.list_extend({ 'agy' }, args), { win = { position = 'right', width = 0.3 } })
  end
end
map('n', '<leader>ag', antigravity({}), { desc = 'Toggle Antigravity' })
map('n', '<leader>aG', antigravity({ '-c' }), { desc = 'Antigravity: continue last conversation' })

-- Space a s sends the line / selection to the agent panel that is open: Antigravity
-- (as "@file#L12" typed at its prompt) or Claude. With both open, the one you were
-- in last wins; with neither, Claude.
local last_agent = 'claude'
local function claude_buf() return require('claudecode.terminal').get_active_terminal_bufnr() end
local function shown(buf) return buf ~= nil and #vim.fn.win_findbuf(buf) > 0 end
vim.api.nvim_create_autocmd({ 'WinEnter', 'BufEnter' }, {
  callback = function()
    local buf = vim.api.nvim_get_current_buf()
    if agy_panel and buf == agy_panel.buf then last_agent = 'agy'
    elseif buf == claude_buf() then last_agent = 'claude' end
  end,
})
local function send_to_agy()
  local agy_open = agy_panel and agy_panel:buf_valid() and shown(agy_panel.buf)
  return agy_open and (last_agent == 'agy' or not shown(claude_buf()))
end
map('n', '<leader>as', function()
  local l = vim.fn.line('.')
  if send_to_agy() then
    local ref = line_ref(l, l)
    if ref then vim.api.nvim_chan_send(vim.bo[agy_panel.buf].channel, ref .. ' ') end
  else
    vim.cmd('ClaudeCodeAdd ' .. vim.fn.fnameescape(vim.fn.expand('%:p')) .. ' ' .. l .. ' ' .. l)
  end
end, { desc = 'Send current line to agent' })
map('x', '<leader>as', function()
  if not send_to_agy() then return vim.api.nvim_feedkeys(':ClaudeCodeSend\r', 'n', false) end
  local a, b = vim.fn.line('v'), vim.fn.line('.')
  vim.api.nvim_feedkeys(vim.keycode('<Esc>'), 'n', false)
  local ref = line_ref(math.min(a, b), math.max(a, b))
  if ref then vim.api.nvim_chan_send(vim.bo[agy_panel.buf].channel, ref .. ' ') end
end, { desc = 'Send selection to agent' })

-- ── Local machine overrides ────────────────────────────────────────────────
-- Machine-specific config (not tracked in git), analogous to ~/.zshrc.local
local local_config = vim.fn.expand('~/.config/nvim/init.local.lua')
if vim.uv.fs_stat(local_config) then
  dofile(local_config)
end

