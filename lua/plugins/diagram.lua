local function supports_terminal_images()
  -- Herdr's headless server has no terminal, even after a remote UI attaches.
  if (vim.uv or vim.loop).guess_handle(1) ~= "tty" then
    return false
  end

  if not vim.env.TMUX then
    return true
  end

  local allow_passthrough = vim.fn.systemlist({ "tmux", "show-options", "-gqv", "allow-passthrough" })[1]
  return vim.v.shell_error == 0 and (allow_passthrough == "on" or allow_passthrough == "all")
end

return {
  {
    "3rd/diagram.nvim",
    cond = supports_terminal_images,
    dependencies = {
      {
        "3rd/image.nvim",
        cond = supports_terminal_images,
        opts = {},
      },
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
