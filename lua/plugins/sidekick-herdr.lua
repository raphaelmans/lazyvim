-- Teach Sidekick about agents running in Herdr app terminals (herdr-core).
--
-- Sidekick only finds agents it started itself, or ones in tmux/zellij. This
-- adds a session backend that lists live Herdr terminals with `hc ls` and
-- delivers text with `hc send`, so <leader>as / <leader>at / <leader>ap can
-- target an agent in any Herdr tab.

-- Herdr's agent name -> Sidekick's tool name, where the two differ.
local aliases = {
  ["claude-code"] = "claude",
  ["cursor-agent"] = "cursor",
  ["q"] = "amazon_q",
}

local CACHE_MS = 2000
local cache = { at = 0, terminals = {} } ---@type {at:number, terminals:table[]}

---@return table[] live Herdr terminals
local function terminals()
  local now = vim.uv.now()
  if now - cache.at < CACHE_MS then
    return cache.terminals
  end
  cache.at = now
  cache.terminals = {}
  local r = vim.system({ "hc", "ls", "--json" }, { text = true }):wait(1000)
  if r.code == 0 then
    local ok, decoded = pcall(vim.json.decode, r.stdout or "")
    if ok and type(decoded) == "table" and type(decoded.terminals) == "table" then
      cache.terminals = decoded.terminals
    end
  end
  return cache.terminals
end

---@class sidekick.cli.session.Herdr: sidekick.cli.Session
---@field herdr_terminal string Herdr terminal address, such as `t7`
---@field herdr_pending? string text waiting for delivery
local M = {}
M.__index = M
M.priority = 10
M.external = true

function M:init()
  self.external = true
  self.priority = 10
end

function M.sessions()
  local Config = require("sidekick.config")
  local tools = Config.tools()
  local ret = {} ---@type sidekick.cli.session.State[]
  for _, t in ipairs(terminals()) do
    local name = aliases[t.agent] or t.agent
    if t.state == "live" and t.address ~= vim.env.HC_TERMINAL_ID and tools[name] then
      ret[#ret + 1] = {
        id = "herdr " .. t.address,
        cwd = t.cwd,
        tool = tools[name],
        herdr_terminal = t.address,
        -- shown in the picker as [herdr:<this>]
        mux_session = t.where and (t.address .. " " .. t.where) or t.address,
        pids = {},
      }
    end
  end
  return ret
end

function M:is_running()
  for _, t in ipairs(terminals()) do
    if t.address == self.herdr_terminal then
      return t.state == "live"
    end
  end
  return false
end

-- The agent already runs in a Herdr terminal: nothing to open in Neovim.
function M:attach() end
function M:detach() end
function M:start() end

---@param text string
function M:deliver(text)
  local Util = require("sidekick.util")
  local name = ("%s (%s)"):format(self.tool.name, self.herdr_terminal)
  -- `hc send` waits for the agent to be ready for input, so never block on it.
  vim.system({ "hc", "send", self.herdr_terminal, text }, { text = true }, function(r)
    vim.schedule(function()
      if r.code == 0 then
        Util.info(("Sent to `%s`"):format(name))
      else
        local err = vim.trim(r.stderr or "")
        Util.error(("Sending to `%s` failed: %s"):format(name, err ~= "" and err or ("exit " .. r.code)))
      end
    end)
  end)
end

-- `hc send` always pastes and presses Enter; Herdr has no paste-only call.
-- So hold the text until we know whether Sidekick will submit it. If it won't,
-- ask for the rest of the message here instead of in the agent's prompt.
---@param text string
function M:send(text)
  self.herdr_pending = (self.herdr_pending or "") .. text
  vim.schedule(function()
    local pending = self.herdr_pending
    if not pending then
      return -- submit() already delivered it
    end
    self.herdr_pending = nil
    pending = vim.trim(pending)
    vim.ui.input({ prompt = ("Message for %s (%s): "):format(self.tool.name, self.herdr_terminal) }, function(msg)
      if msg == nil then
        return -- cancelled
      end
      msg = vim.trim(msg)
      local parts = {}
      if pending ~= "" then
        parts[#parts + 1] = pending
      end
      if msg ~= "" then
        parts[#parts + 1] = msg
      end
      if #parts > 0 then
        self:deliver(table.concat(parts, pending:find("\n") and "\n\n" or " "))
      end
    end)
  end)
end

function M:submit()
  local pending = self.herdr_pending
  self.herdr_pending = nil
  if pending and vim.trim(pending) ~= "" then
    self:deliver(vim.trim(pending))
  else
    vim.system({ "hc", "keys", self.herdr_terminal, "enter" })
  end
end

function M:dump()
  local r = vim.system({ "hc", "read", self.herdr_terminal }, { text = true }):wait(1000)
  return r.code == 0 and r.stdout or nil
end

return {
  {
    "folke/sidekick.nvim",
    optional = true,
    opts = function()
      if vim.fn.executable("hc") ~= 1 then
        return
      end
      -- Sidekick registers its backends lazily in Session.setup(); add ours
      -- right after, so it also sees the configured tools.
      local Session = require("sidekick.cli.session")
      local setup = Session.setup
      Session.setup = function()
        setup()
        if not Session.backends.herdr then
          Session.register("herdr", M)
        end
      end
    end,
  },
}
