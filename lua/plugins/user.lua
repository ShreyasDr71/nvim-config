-- NO "if true then return {} end" here!
return {
  -- == Examples of Adding Plugins ==
  "andweeb/presence.nvim",
  {
    "ray-x/lsp_signature.nvim",
    event = "BufRead",
    config = function() require("lsp_signature").setup() end,
  },

  -- == Examples of Overriding Plugins ==
  {
    "folke/snacks.nvim",
    opts = {
      dashboard = {
        preset = {
          header = table.concat({
            "  ▄▄▄▄   ▄▄▄                                       ",
            " █▀ ██  ██                  █▄             ▄       ",
            "    ██ ██                   ██       ▄     ▀       ",
            "   █████    ▄▀▀█▄ ██ ██ ▄████ ▄█▀█▄ ████▄    ▄██▀█ ",
            "   ██ ██▄   ▄█▀██ ██▄██ ██ ██ ██▄█▀ ██ ██    ▀███▄ ",
            " ▀██▀  ▀██▄▄▀█▄██▄▄▀██▀▄█▀███▄▀█▄▄▄▄██ ▀█   █▄▄██▀ ",
            "                    ██                             ",
            "                  ▀▀▀                              ",
            "",
            "███    ██ ██    ██ ██ ███    ███",
            "████   ██ ██    ██ ██ ████  ████",
            "██ ██  ██ ██    ██ ██ ██ ████ ██",
            "██  ██ ██  ██  ██  ██ ██  ██  ██",
            "██   ████   ████   ██ ██      ██",
          }, "\n"),
        },
      },
    },
  },

  -- Disable default plugins
  { "max397574/better-escape.nvim", enabled = false },

  -- LuaSnip Customization
  {
    "L3MON4D3/LuaSnip",
    config = function(plugin, opts)
      local luasnip = require "luasnip"
      luasnip.filetype_extend("javascript", { "javascriptreact" })
      require "astronvim.plugins.configs.luasnip"(plugin, opts)
    end,
  },

  -- Nvim-autopairs Customization
  {
    "windwp/nvim-autopairs",
    config = function(plugin, opts)
      require "astronvim.plugins.configs.nvim-autopairs"(plugin, opts)
      local npairs = require "nvim-autopairs"
      local Rule = require "nvim-autopairs.rule"
      local cond = require "nvim-autopairs.conds"
      npairs.add_rules({
        Rule("$", "$", { "tex", "latex" })
          :with_pair(cond.not_after_regex "%%")
          :with_pair(cond.not_before_regex("xxx", 3))
          :with_move(cond.none())
          :with_del(cond.not_after_regex "xx")
          :with_cr(cond.none()),
        Rule("a", "a", "-vim")
      })
    end,
  },
}