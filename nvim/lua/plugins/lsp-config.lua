return {
	{
		"williamboman/mason.nvim",
		config = function()
			require("mason").setup()
		end
	},
	{
		"williamboman/mason-lspconfig.nvim",
		config = function()
			require("mason-lspconfig").setup({
				ensure_installed = { "lua_ls", "ast_grep", "clangd" }
			})
		end
	},
	{
		"neovim/nvim-lspconfig",
		config = function()
			local lspconfig = require("lspconfig")
			lspconfig.lua_ls.setup({})
			lspconfig.ast_grep.setup({})
			lspconfig.clangd.setup({})

			vim.keymap.set("n", "gd", vim.lsp.buf.definition, {})
			vim.keymap.set({ "n" }, "<space>ca", vim.lsp.buf.code_action, {})
			vim.keymap.set("n", "<space>f", function() vim.lsp.buf.format() end)
		end
	},
}
