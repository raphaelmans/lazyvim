return {
  {
    "folke/snacks.nvim",
    opts = {
      picker = {
        sources = {
          explorer = {
            hidden = true, -- see .env, .gitignore, etc in sidebar
            ignored = true, -- see node_modules, dist, etc in sidebar
          },
          files = {
            hidden = true, -- Ctrl+P finds dotfiles
            ignored = false, -- Ctrl+P ignores node_modules (default)
          },
          grep = {
            hidden = true, -- search finds matches in dotfiles
            ignored = false, -- search ignores node_modules (default)
          },
        },
      },
    },
  },
}
