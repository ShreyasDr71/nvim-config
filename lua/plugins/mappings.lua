return {
  {
    "AstroNvim/astrocore",
    ---@type AstroCoreOpts
    opts = {
      mappings = {
        n = {
          -- Terminal in current file's directory
          ["<Leader>th"] = { "<cmd>ToggleTerm direction=horizontal dir=%:p:h<cr>", desc = "Terminal horizontal (file dir)" },
          ["<Leader>tv"] = { "<cmd>ToggleTerm direction=vertical dir=%:p:h<cr>", desc = "Terminal vertical (file dir)" },
          
          -- Quick Run Python
          ["<Leader>rp"] = { "<cmd>w<cr><cmd>ToggleTerm direction=horizontal dir=%:p:h cmd='python3 %'<cr>", desc = "Run Python file" },
        },
      },
    },
  },
}
