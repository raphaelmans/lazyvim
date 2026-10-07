return {
  {
    "ChmaraX/herdr-nvim",
    lazy = false,
    -- Herdr's launcher calls setup again. Let Lazy own the mappings so that
    -- repeated setup is harmless, and keep Sidekick's <leader>as binding.
    opts = { keymaps = false },
    keys = {
      {
        "<leader>ac",
        function()
          require("herdr-nvim").comment_line()
        end,
        desc = "Herdr: comment line",
      },
      {
        "<leader>ac",
        function()
          require("herdr-nvim").comment_selection()
        end,
        mode = "x",
        desc = "Herdr: comment selection",
      },
      {
        "<leader>al",
        function()
          require("herdr-nvim").list_comments()
        end,
        desc = "Herdr: list comments",
      },
      {
        "<leader>aP",
        function()
          require("herdr-nvim").send_all({ submit = false })
        end,
        desc = "Herdr: paste comments to agent",
      },
      {
        "<leader>aS",
        function()
          require("herdr-nvim").send_all({ submit = true })
        end,
        desc = "Herdr: send comments to agent",
      },
      {
        "<leader>ai",
        function()
          require("herdr-nvim").ref_line()
        end,
        desc = "Herdr: reference line at agent cursor",
      },
      {
        "<leader>ai",
        function()
          require("herdr-nvim").ref_selection()
        end,
        mode = "x",
        desc = "Herdr: reference selection at agent cursor",
      },
    },
  },
}
