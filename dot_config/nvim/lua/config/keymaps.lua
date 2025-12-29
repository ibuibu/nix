-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local map = vim.keymap.set

-- Save
map("n", "<leader>w", ":w<CR>", { desc = "Save" })

-- Yank
map("v", "<leader>y", '"+y', { desc = "Yank to clipboard" })

-- Buffer
map("n", "<C-j>", "<cmd>bprevious<cr>", { desc = "Prev Buffer" })
map("n", "<C-k>", "<cmd>bnext<cr>", { desc = "Next Buffer" })
map("n", "<C-q>", function()
  Snacks.bufdelete()
end, { desc = "Delete Buffer" })
