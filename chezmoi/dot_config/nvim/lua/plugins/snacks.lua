return {
  "folke/snacks.nvim",
  opts = {
    picker = {
      sources = {
        -- <leader>sg のライブ grep で hidden ファイル(dotfiles)も最初から対象にする
        -- (<a-h> の toggle_hidden を最初からオンにした状態)
        grep = { hidden = true },
      },
    },
  },
}
