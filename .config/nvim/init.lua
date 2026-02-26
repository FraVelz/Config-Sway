vim.g.base46_cache = vim.fn.stdpath "data" .. "/base46/"
vim.g.mapleader = " "

-- bootstrap lazy and all plugins
local lazypath = vim.fn.stdpath "data" .. "/lazy/lazy.nvim"

if not vim.uv.fs_stat(lazypath) then
  local repo = "https://github.com/folke/lazy.nvim.git"
  vim.fn.system { "git", "clone", "--filter=blob:none", repo, "--branch=stable", lazypath }
end

vim.opt.rtp:prepend(lazypath)

local lazy_config = require "configs.lazy"

-- load plugins
require("lazy").setup({
  { "nvzone/volt" , lazy = true },
  { "nvzone/menu" , lazy = true },

  {
    "NvChad/NvChad",
    lazy = false,
    branch = "v2.5",
    import = "nvchad.plugins",
  },

  { import = "plugins" },
}, lazy_config)

-- load theme
dofile(vim.g.base46_cache .. "defaults")
dofile(vim.g.base46_cache .. "statusline")

require "options"
require "autocmds"

vim.schedule(function()
  require "mappings"
end)

-- Keyboard users
vim.keymap.set("n", "<C-t>", function()
  require("menu").open("default")
end, {})

-- mouse users + nvimtree users!
vim.keymap.set({ "n", "v" }, "<RightMouse>", function()
  require('menu.utils').delete_old_menus()

  vim.cmd.exec '"normal! \\<RightMouse>"'

  -- clicked buf
  local buf = vim.api.nvim_win_get_buf(vim.fn.getmousepos().winid)
  local options = vim.bo[buf].ft == "NvimTree" and "nvimtree" or "default"

  require("menu").open(options, { mouse = true })
end, {})

-----------------------------------------------------------
-- 🧩 CONFIGURACIÓN GENERAL DE NEOVIM
-----------------------------------------------------------

-- Numeración de líneas
vim.opt.number = true
vim.opt.relativenumber = true

-----------------------------------------------------------
-- ⌨️ ATAJOS DE TECLADO (KEYMAPS) -----------------------------------------------------------

-- Atajos de movimiento entre ventanas (pane navigation)
vim.keymap.set('n', '<C-h>', '<C-w>h', { desc = "Mover al panel izquierdo" })
vim.keymap.set('n', '<C-l>', '<C-w>l', { desc = "Mover al panel derecho" })

-----------------------------------------------------------
-- 🧱 Salir del modo actual con 'zx'
-----------------------------------------------------------

vim.keymap.set('i', 'zx', '<Esc>', { noremap = true, desc = "Salir del modo inserción" })
vim.keymap.set('v', 'zx', '<Esc>', { noremap = true, desc = "Salir del modo visual" })
vim.keymap.set('c', 'zx', '<C-c>', { noremap = true, desc = "Cancelar comando" })
vim.keymap.set('t', 'zx', '<C-\\><C-n>', { noremap = true, desc = "Salir del modo terminal" })
