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
-- window on the left. (Esc is left alone: Claude Code uses Esc Esc itself.
-- To scroll/copy terminal output, leave terminal mode with Ctrl+\ Ctrl+n.)
map('t', '<C-h>', '<C-\\><C-n><cmd>TmuxNavigateLeft<CR>', { desc = 'Window/pane left' })
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
local function copy_line_ref(l1, l2)
  local path = vim.fn.expand('%:.')
  if path == '' then return vim.notify('Buffer has no file', vim.log.levels.WARN) end
  local ref = '@' .. path .. '#L' .. l1 .. (l1 == l2 and '' or '-' .. l2)
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
  { '<leader>a', group = 'AI / Claude' },
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
map('n', '<C-n>', toggle_explorer, { desc = 'Toggle file explorer sidebar' })
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
map('x', '<leader>as', '<cmd>ClaudeCodeSend<CR>', { desc = 'Send selection' })
map('n', '<leader>as', function()
  local l = vim.fn.line('.')
  vim.cmd('ClaudeCodeAdd ' .. vim.fn.fnameescape(vim.fn.expand('%:p')) .. ' ' .. l .. ' ' .. l)
end, { desc = 'Send current line' })
map('n', '<leader>aa', '<cmd>ClaudeCodeDiffAccept<CR>', { desc = 'Accept diff' })
map('n', '<leader>ad', '<cmd>ClaudeCodeDiffDeny<CR>', { desc = 'Deny diff' })

-- ── Local machine overrides ────────────────────────────────────────────────
-- Machine-specific config (not tracked in git), analogous to ~/.zshrc.local
local local_config = vim.fn.expand('~/.config/nvim/init.local.lua')
if vim.uv.fs_stat(local_config) then
  dofile(local_config)
end

