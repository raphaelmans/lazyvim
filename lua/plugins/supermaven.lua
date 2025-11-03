return {
  {
    "supermaven-inc/supermaven-nvim",
    config = function()
      require("supermaven-nvim").setup({
        keymaps = {
          accept_suggestion = "<C-j>",
          clear_suggestion = "<C-]>",
        },
        enable_inline_completion = true,
        enable_autosuggestions = true,
      })
    end,
  },
}
