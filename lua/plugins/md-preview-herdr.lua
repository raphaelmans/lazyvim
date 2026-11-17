-- Markdown preview in a Herdr popup.
--
-- <leader>mp in a markdown buffer saves it and opens a rendered, read-only
-- nvim in a Herdr popup (render-markdown.nvim). Press q or <Esc> to close it.
--
-- The popup comes from the local Herdr plugin in
-- ~/.config/herdr/local-plugins/md-preview, which starts nvim with
-- MD_PREVIEW=1. That switches on the preview-mode settings at the bottom.

local function open_popup()
  local file = vim.api.nvim_buf_get_name(0)
  if file == "" then
    vim.notify("Save the buffer first", vim.log.levels.WARN)
    return
  end

  if vim.bo.modified then
    vim.cmd("silent write")
  end

  local in_tui = vim.fn.executable("herdr") == 1 and (vim.env.HERDR_ENV ~= nil or vim.env.HERDR_SOCKET_PATH ~= nil)
  if not in_tui then
    -- Herdr desktop app: the md-popup mod renders the file natively.
    if vim.fn.executable("herdr-app") == 1 then
      local home = vim.fn.expand("~/.config/herdr-app")
      vim.fn.writefile({ file }, home .. "/mods/md-popup/.file")
      local res = vim.fn.system({ "herdr-app", "do", "mod.open", '{"name":"md-popup"}' })
      if vim.v.shell_error == 0 then
        return
      end
      vim.notify("Herdr app preview failed: " .. res, vim.log.levels.WARN)
    end
    -- Outside Herdr: the browser preview from the LazyVim extra.
    vim.cmd("MarkdownPreviewToggle")
    return
  end

  local out = vim.fn.system({
    "herdr",
    "plugin",
    "pane",
    "open",
    "--plugin",
    "local.md-preview",
    "--entrypoint",
    "preview",
    "--placement",
    "popup",
    "--width",
    "90%",
    "--height",
    "90%",
    "--env",
    "MD_FILE=" .. file,
    "--env",
    "MD_NVIM=" .. vim.v.progpath,
  })
  if vim.v.shell_error ~= 0 then
    vim.notify("Markdown preview failed: " .. out, vim.log.levels.ERROR)
  end
end

-- Inside the preview nvim.
if vim.env.MD_PREVIEW then
  vim.api.nvim_create_autocmd("VimEnter", {
    callback = function()
      vim.o.autoread = true
      vim.o.modifiable = false
      vim.o.number = false
      vim.o.relativenumber = false
      vim.o.signcolumn = "no"
      for _, key in ipairs({ "q", "<Esc>" }) do
        vim.keymap.set("n", key, "<cmd>qa!<cr>", { desc = "Close preview" })
      end
    end,
  })
  -- Pick up saves made elsewhere while the popup is open.
  local timer = (vim.uv or vim.loop).new_timer()
  timer:start(
    500,
    500,
    vim.schedule_wrap(function()
      pcall(vim.cmd, "silent! checktime")
    end)
  )
end

return {
  {
    "MeanderingProgrammer/render-markdown.nvim",
    opts = function(_, opts)
      if vim.env.MD_PREVIEW then
        -- Render in every mode and never reveal raw markdown under the cursor.
        opts.render_modes = true
        opts.anti_conceal = { enabled = false }
      end
    end,
    keys = {
      { "<leader>mp", open_popup, ft = { "markdown" }, desc = "Markdown preview (Herdr popup)" },
    },
  },
}
