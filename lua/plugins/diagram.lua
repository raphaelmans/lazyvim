return {
  {
    "3rd/diagram.nvim",
    dependencies = {
      { "3rd/image.nvim", opts = {} },
    },
    ft = { "markdown", "norg" },
    opts = {
      events = {
        render_buffer = { "InsertLeave", "BufWinEnter", "TextChanged" },
        clear_buffer = { "BufLeave" },
      },
    },
    keys = {
      {
        "<leader>cd",
        function()
          require("diagram").show_diagram_hover()
        end,
        mode = "n",
        ft = { "markdown", "norg" },
        desc = "Show diagram hover",
      },
    },
  },
}
