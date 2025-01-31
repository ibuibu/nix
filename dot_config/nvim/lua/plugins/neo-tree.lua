return {
  "nvim-neo-tree/neo-tree.nvim",
  opts = {
    filesystem = {
      filtered_items = {
        visible = true,
        hide_dotfiles = false,
        never_show = {
          ".DS_Store",
        },
      },
    },
  },
  keys = {
    { "<C-e>", "<leader>fe", desc = "Explorer NeoTree (Root Dir)", remap = true },
  },
  config = function(_, opts)
    require("neo-tree").setup(opts)
  end,
}
