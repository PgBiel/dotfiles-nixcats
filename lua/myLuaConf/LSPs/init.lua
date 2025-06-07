-- PG: Support Rust
-- TODO: Check for the presence of rust
if true then
  local on_attach = function(client, bufnr)
    -- require("completion").on_attach(client) -- i think this is already handled
    vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })-- rustaceanvim overrides
    vim.keymap.set(
      "n",
      "<leader>ca",
      function()
        vim.cmd.RustLsp('codeAction') -- supports rust-analyzer's grouping
        -- or vim.lsp.buf.codeAction() if you don't want grouping.
      end,
      { silent = true, buffer = bufnr, desc = "Rust: [C]ode [A]ction" }
    )
    vim.keymap.set(
      "n",
      "K",  -- Override Neovim's built-in hover keymap with rustaceanvim's hover actions
      function()
        vim.cmd.RustLsp({'hover', 'actions'})
      end,
      { silent = true, buffer = bufnr, desc = "Hover (Rustacean)" }
    )
    vim.keymap.set(
      "n",
      "T",  -- Override Neovim's built-in hover keymap with rustaceanvim's hover actions
      function()
        vim.cmd.RustLsp({'hover', 'actions'})
      end,
      { silent = true, buffer = bufnr, desc = "Hover (Rustacean - shortcut)" }
    )
  end
  local rust_analyzer = {
    diagnostics = {
      enable = true,
      experimental = {
        enable = true,
      },
    },
    imports = {
      granularity = {
        group = "module",
      },
      prefix = "self",
    },
    cargo = {
      buildScripts = {
        enable = true,
      },
    },
    procMacro = {
      enable = true
    },
  }

  -- Configure rustaceanvim, with extensions on top of base R-A
  vim.g.rustaceanvim = {
    tools = {
      -- Don't run cargo clippy on each save,
      -- rather run just cargo check
      enable_clippy = false,
    },
    server = {
      on_attach = on_attach,
      default_settings = {
        ["rust-analyzer"] = rust_analyzer,
      },
    },
  }
end



-- PG: Update diagnostic signs (https://github.com/folke/trouble.nvim/issues/52):

local signs = {
    Error = " ",
    Warn = " ",
    Hint = "󰌵 ",
    Info = " "
}

local signConf = {
  text = {},
  texthl = {},
  numhl = {},
}

for type, icon in pairs(signs) do
  local severityName = string.upper(type)
  local severity = vim.diagnostic.severity[severityName]
  local hl = "DiagnosticSign" .. type
  signConf.text[severity] = icon
  signConf.texthl[severity] = hl
  signConf.numhl[severity] = hl
end

vim.diagnostic.config({
  signs = signConf,
})

----

local catUtils = require('nixCatsUtils')
if (catUtils.isNixCats and nixCats('lspDebugMode')) then
  vim.lsp.set_log_level("debug")
end


-- NOTE: This file uses lzextras.lsp handler https://github.com/BirdeeHub/lzextras?tab=readme-ov-file#lsp-handler
-- This is a slightly more performant fallback function
-- for when you don't provide a filetype to trigger on yourself.
-- nixCats gives us the paths, which is faster than searching the rtp!
local old_ft_fallback = require('lze').h.lsp.get_ft_fallback()
require('lze').h.lsp.set_ft_fallback(function(name)
  local lspcfg = nixCats.pawsible({ "allPlugins", "opt", "nvim-lspconfig" }) or nixCats.pawsible({ "allPlugins", "start", "nvim-lspconfig" })
  if lspcfg then
    local ok, cfg = pcall(dofile, lspcfg .. "/lsp/" .. name .. ".lua")
    if not ok then
      ok, cfg = pcall(dofile, lspcfg .. "/lua/lspconfig/configs/" .. name .. ".lua")
    end
    return (ok and cfg or {}).filetypes or {}
  else
    return old_ft_fallback(name)
  end
end)

require('lze').load {
  {
    "nvim-lspconfig",
    for_cat = "general.core",
    on_require = { "lspconfig" },
    -- NOTE: define a function for lsp,
    -- and it will run for all specs with type(plugin.lsp) == table
    -- when their filetype trigger loads them
    lsp = function(plugin)
      vim.lsp.config(plugin.name, plugin.lsp or {})
      vim.lsp.enable(plugin.name)
    end,
    before = function(_)
      vim.lsp.config('*', {
        on_attach = require('myLuaConf.LSPs.on_attach'),
      })
    end,
  },
  {
    "mason.nvim",
    -- only run it when not on nix
    enabled = not catUtils.isNixCats,
    on_plugin = { "nvim-lspconfig" },
    load = function(name)
      vim.cmd.packadd(name)
      vim.cmd.packadd("mason-lspconfig.nvim")
      require('mason').setup()
      -- auto install will make it install servers when lspconfig is called on them.
      require('mason-lspconfig').setup { automatic_installation = true, }
    end,
  },
  {
    -- lazydev makes your lsp way better in your config without needing extra lsp configuration.
    "lazydev.nvim",
    for_cat = "neonixdev",
    cmd = { "LazyDev" },
    ft = "lua",
    after = function(_)
      require('lazydev').setup({
        library = {
          { words = { "nixCats" }, path = (nixCats.nixCatsPath or "") .. '/lua' },
        },
      })
    end,
  },
  {
    -- name of the lsp
    "lua_ls",
    enabled = nixCats('lua') or nixCats('neonixdev') or false,
    -- provide a table containing filetypes,
    -- and then whatever your functions defined in the function type specs expect.
    -- in our case, it just expects the normal lspconfig setup options,
    -- but with a default on_attach and capabilities
    lsp = {
      -- if you provide the filetypes it doesn't ask lspconfig for the filetypes
      filetypes = { 'lua' },
      settings = {
        Lua = {
          runtime = { version = 'LuaJIT' },
          formatters = {
            ignoreComments = true,
          },
          signatureHelp = { enabled = true },
          diagnostics = {
            globals = { "nixCats", "vim", },
            disable = { 'missing-fields' },
          },
          telemetry = { enabled = false },
        },
      },
    },
    -- also these are regular specs and you can use before and after and all the other normal fields
  },
  {
    "gopls",
    for_cat = "go",
    -- if you don't provide the filetypes it asks lspconfig for them
    lsp = {
      filetypes = { "go", "gomod", "gowork", "gotmpl" },
    },
  },
  {
    "rnix",
    -- mason doesn't have nixd
    enabled = not catUtils.isNixCats,
    lsp = {
      filetypes = { "nix" },
    },
  },
  {
    "nil_ls",
    -- mason doesn't have nixd
    enabled = not catUtils.isNixCats,
    lsp = {
      filetypes = { "nix" },
    },
  },
  {
    "nixd",
    enabled = catUtils.isNixCats and (nixCats('nix') or nixCats('neonixdev')) or false,
    lsp = {
      filetypes = { "nix" },
      settings = {
        nixd = {
          -- nixd requires some configuration.
          -- luckily, the nixCats plugin is here to pass whatever we need!
          -- we passed this in via the `extra` table in our packageDefinitions
          -- for additional configuration options, refer to:
          -- https://github.com/nix-community/nixd/blob/main/nixd/docs/configuration.md
          nixpkgs = {
            -- in the extras set of your package definition:
            -- nixdExtras.nixpkgs = ''import ${pkgs.path} {}''
            expr = nixCats.extra("nixdExtras.nixpkgs") or [[import <nixpkgs> {}]],
          },
          options = {
            -- If you integrated with your system flake,
            -- you should use inputs.self as the path to your system flake
            -- that way it will ALWAYS work, regardless
            -- of where your config actually was.
            nixos = {
              -- nixdExtras.nixos_options = ''(builtins.getFlake "path:${builtins.toString inputs.self.outPath}").nixosConfigurations.configname.options''
              expr = nixCats.extra("nixdExtras.nixos_options")
            },
            -- If you have your config as a separate flake, inputs.self would be referring to the wrong flake.
            -- You can override the correct one into your package definition on import in your main configuration,
            -- or just put an absolute path to where it usually is and accept the impurity.
            ["home-manager"] = {
              -- nixdExtras.home_manager_options = ''(builtins.getFlake "path:${builtins.toString inputs.self.outPath}").homeConfigurations.configname.options''
              expr = nixCats.extra("nixdExtras.home_manager_options")
            }
          },
          formatting = {
            command = { "nixfmt" }
          },
          diagnostic = {
            suppress = {
              "sema-escaping-with"
            }
          }
        }
      },
    },
  },
  -- PG: Nushell LSP
  {
    "nushell",
    lsp = {
      filetypes = { "nu" },
    }
  },
  -- PG: Gleam LSP
  {
    "gleam",
    lsp = {
      filetypes = { "gleam" },
    }
  },
  -- PG: Typst LSP (only if tinymist is installed)
  {
    "tinymist",
    enabled = vim.fn.executable("tinymist") == 1,
    lsp = {
      settings = {
        tinymist = {
          formatterMode = "typstyle",
        }
      }
    }
  }
}
