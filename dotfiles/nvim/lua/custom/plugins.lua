local plugins = {
  {
    "github/copilot.vim",
  lazy = false,
  config = function()  -- Mapping tab is already used by NvChad
  --   vim.g.copilot_no_tab_map = true;
  --   vim.g.copilot_assume_mapped = true;
  --   vim.g.copilot_tab_fallback = "<C-Tab>";
  -- -- The mapping is set to other key, see custom/lua/mappings
  -- -- or run <leader>ch to see copilot mapping section
  --   vim.api.nvim_set_keymap("i", "<C-Tab>", 'copilot#Accept("<CR>")', { expr = true, silent = true, noremap = true })
  end
  },
  {
    "tpope/vim-fugitive",
    lazy = false,
    config = function()
    end
  },
  {
    "neovim/nvim-lspconfig",
    config = function()
      require "plugins.configs.lspconfig"
      require "custom.configs.lspconfig"
    end,
  },
  {
    "williamboman/mason.nvim",
    opts = {
      ensure_installed = {
        "eslint-lsp",
        "prettierd",
        "tailwindcss-language-server",
        "typescript-language-server",
      },
    },
  },
  {
    "nvimtools/none-ls.nvim",
    event = "VeryLazy",
    opts = function()
      return require "custom.configs.null-ls"
    end,
  },
  {
    "windwp/nvim-ts-autotag",
    ft = {"javascript", "javascriptreact", "typescript", "typescriptreact"},
    config = function()
      require("nvim-ts-autotag").setup()
    end,
  },
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function()
      local opts = require "plugins.configs.treesitter"
      opts.ensure_installed = {
        "lua",
        "javascript",
        "typescript",
        "tsx",
      }
      return opts
    end,
  },
  -- {
  --   "pwntester/octo.nvim",
  --   lazy = false,
  --   ft = "octo",
  --   config = function()
  --     require("octo").setup()
  --   end,
  -- }
}
return plugins
