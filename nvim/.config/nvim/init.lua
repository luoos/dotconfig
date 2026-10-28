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
o.clipboard = 'unnamedplus'   -- yank/paste use the macOS clipboard
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

-- ── Colors: use Ghostty's 16-color palette (Breadog), like ~/.vimrc ─────
o.termguicolors = false
o.background = 'light'
vim.cmd.colorscheme('default')
local function search_colors()
  vim.api.nvim_set_hl(0, 'Search', { ctermfg = 0, ctermbg = 7 })
  vim.api.nvim_set_hl(0, 'CurSearch', { ctermfg = 15, ctermbg = 11, bold = true })
  vim.api.nvim_set_hl(0, 'IncSearch', { ctermfg = 15, ctermbg = 11, bold = true })
end
search_colors()
vim.api.nvim_create_autocmd('ColorScheme', { callback = search_colors })

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
vim.pack.add({
  'https://github.com/folke/snacks.nvim',        -- picker, terminal (used by claudecode)
  'https://github.com/coder/claudecode.nvim',    -- Claude Code integration, like Zed/VS Code
  'https://github.com/lewis6991/gitsigns.nvim',  -- git changes in the sign column
  'https://github.com/folke/which-key.nvim',     -- popup listing keymaps after <Space>
  'https://github.com/neovim/nvim-lspconfig',    -- ready-made language server configs
  'https://github.com/mason-org/mason.nvim',     -- :Mason installs language servers
  'https://github.com/mason-org/mason-lspconfig.nvim', -- enables servers Mason installed
  'https://github.com/christoomey/vim-tmux-navigator', -- Ctrl+h/j/k/l across Neovim and tmux
}, { confirm = false })

require('snacks').setup({
  picker = { enabled = true },
  terminal = { enabled = true },
  input = { enabled = true },
})
require('gitsigns').setup()
require('which-key').setup({ delay = 300 })
require('which-key').add({
  { '<leader>a', group = 'AI / Claude' },
  { '<leader>f', group = 'Find' },
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
map('n', '<leader><leader>', pick('files'), { desc = 'Find files' })
map('n', '<leader>ff', pick('files'), { desc = 'Files' })
map('n', '<leader>fg', pick('grep'), { desc = 'Grep' })
map('n', '<leader>fb', pick('buffers'), { desc = 'Buffers' })
map('n', '<leader>fr', pick('recent'), { desc = 'Recent files' })
map('n', '<leader>fh', pick('help'), { desc = 'Help' })
map({ 'n', 'x' }, '<leader>fw', pick('grep_word'), { desc = 'Word under cursor' })

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
