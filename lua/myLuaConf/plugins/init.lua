local colorschemeName = nixCats('colorscheme')
if not require('nixCatsUtils').isNixCats then
  colorschemeName = 'onedark'
end
-- Could I lazy load on colorscheme with lze?
-- sure. But I was going to call vim.cmd.colorscheme() during startup anyway
-- this is just an example, feel free to do a better job!
vim.cmd.colorscheme(colorschemeName)

-- NOTE: you can check if you included the category with the thing wherever you want.
if nixCats('general.extra') then
  -- I didnt want to bother with lazy loading this.
  -- I could put it in opt and put it in a spec anyway
  -- and then not set any handlers and it would load at startup,
  -- but why... I guess I could make it load
  -- after the other lze definitions in the next call using priority value?
  -- didnt seem necessary.
  vim.g.loaded_netrwPlugin = 1
  require("oil").setup({
    default_file_explorer = true,
    columns = {
      "icon",
      "permissions",
      "size",
      -- "mtime",
    },
    keymaps = {
      ["g?"] = "actions.show_help",
      ["<CR>"] = "actions.select",
      ["<C-s>"] = "actions.select_vsplit",
      ["<C-h>"] = "actions.select_split",
      ["<C-t>"] = "actions.select_tab",
      ["<C-p>"] = "actions.preview",
      ["<C-c>"] = "actions.close",
      ["<C-l>"] = "actions.refresh",
      ["-"] = "actions.parent",
      ["_"] = "actions.open_cwd",
      ["`"] = "actions.cd",
      ["~"] = "actions.tcd",
      ["gs"] = "actions.change_sort",
      ["gx"] = "actions.open_external",
      ["g."] = "actions.toggle_hidden",
      ["g\\"] = "actions.toggle_trash",
    },
  })
  vim.keymap.set("n", "-", "<cmd>Oil<CR>", { noremap = true, desc = 'Open Parent Directory' })
  vim.keymap.set("n", "<leader>-", "<cmd>Oil .<CR>", { noremap = true, desc = 'Open nvim root directory' })
end

require('lze').load {
  { import = "myLuaConf.plugins.telescope", },
  { import = "myLuaConf.plugins.treesitter", },
  -- { import = "myLuaConf.plugins.completion", },

  -- PG: Let's try out new completion with blink.cmp
  { import = "myLuaConf.plugins.blink-cmp", },

  -- PG: Add nvim-tree for directory browsing
  -- Loads lazily on the commands and keys below
  {
    "nvim-tree",
    for_cat = "general.always",
    cmd = { "NvimTreeToggle", "NvimTreeOpen", "NvimTreeClose", "NvimTreeFocus" },
    keys = {
      {"<leader>tt", "<cmd>NvimTreeToggle <CR>", mode = "n", noremap = true, desc = "Toggle nvim-tree"},
    },
    before = function(_)
      vim.g.loaded_netrw = 1
      vim.g.loaded_netrwPlugin = 1
    end,
    after = function(_)
      local function my_on_attach(bufnr)
        local api = require "nvim-tree.api"
        local function opts(desc)
          return { desc = "nvim-tree: " .. desc, buffer = bufnr, noremap = true, silent = true, nowait = true }
        end

        -- default mappings
        api.config.mappings.default_on_attach(bufnr)

        -- custom mappings
        vim.keymap.set("n", "<C-t>", api.tree.change_root_to_parent,        opts("Up"))
        vim.keymap.set("n", "?",     api.tree.toggle_help,                  opts("Help"))
      end
      require("nvim-tree").setup {
        on_attach = my_on_attach,
        -- When a file is opened, show it on the tree automatically
        update_focused_file = {
          enable = true,
        },
        filters = {
          -- Show .gitignored files by default
          -- (they have a special indicator anyway)
          git_ignored = false,
        },
      }
    end,
  },
  -- PG: Scrollbar showing git info, search results, diagnostics
  {
    "nvim-scrollbar",
    for_cat = "general.always",
    event = "DeferredUIEnter",
    dep_of = "nvim-hlslens", -- Ensure hlslens is initialized after scrollbar to use its hook
    after = function(_)
      local colors = require("dracula").colors()
      require("scrollbar").setup({
        marks = {
          Cursor = { color = colors.white },
          -- Otherwise unreadable on dracula theme
          Search = { color = colors.orange },
          Misc = { color = colors.white },
          Error = { color = colors.red },
          Warn = { color = colors.yellow },
          Info = { color = colors.bright_cyan },
        },
      })

      -- Integrate gitsigns with scrollbar
      -- (scrollbar is in gitsigns dep-of so it runs afterwards)
      require("scrollbar.handlers.gitsigns").setup()
    end,
  },
  -- PG: hlslens for advanced search results
  {
    "nvim-hlslens",
    for_cat = "general.always",
    event = "DeferredUIEnter",
    keys = {
      -- {'/', [[<Cmd>execute("normal /\\<CR>")<CR>]], mode = 'n', remap = false, silent = true }, -- TODO: Trigger on search
      {'n', [[<Cmd>execute('normal! ' . v:count1 . 'n')<CR><Cmd>lua require('hlslens').start()<CR>]], mode = 'n', remap = false, silent = true},
      {'N', [[<Cmd>execute('normal! ' . v:count1 . 'N')<CR><Cmd>lua require('hlslens').start()<CR>]], mode = 'n', remap = false, silent = true},
      {'*', [[*<Cmd>lua require('hlslens').start()<CR>]],  mode = 'n', remap = false, silent = true},
      {'#', [[#<Cmd>lua require('hlslens').start()<CR>]],  mode = 'n', remap = false, silent = true},
      {'g*', [[g*<Cmd>lua require('hlslens').start()<CR>]], mode = 'n', remap = false, silent = true},
      {'g#', [[g#<Cmd>lua require('hlslens').start()<CR>]], mode = 'n', remap = false, silent = true},
      {'<Leader>l', '<Cmd>noh<CR>', mode = 'n', remap = false, silent = true},
    },
    after = function(_)
      -- (Note: this replaces hlslens' original setup)
      require("scrollbar.handlers.search").setup()
    end,
  },
  -- PG: Mouse hover info
  {
    "hover.nvim",
    for_cat = "general.extra",
    event = "DeferredUIEnter",
    after = function(_)
      require("hover").setup {
          init = function()
              -- Require providers
              require("hover.providers.lsp")
              -- require('hover.providers.gh')
              -- require('hover.providers.gh_user')
              -- require('hover.providers.jira')
              -- require('hover.providers.dap')
              require('hover.providers.fold_preview')
              require('hover.providers.diagnostic')
              -- require('hover.providers.man')
              -- require('hover.providers.dictionary')
          end,
          preview_opts = {
              border = 'single'
          },
          -- Whether the contents of a currently open hover window should be moved
          -- to a :h preview-window when pressing the hover keymap.
          preview_window = false,
          title = true,
          mouse_providers = {
            "LSP",
            "Diagnostics",
            "Fold Preview",
          },
          mouse_delay = 1000
      }

      -- Setup keymaps
      vim.keymap.set("n", "K", require("hover").hover, {desc = "hover.nvim"})
      vim.keymap.set("n", "gK", require("hover").hover_select, {desc = "hover.nvim (select)"})
      -- vim.keymap.set("n", "<C-p>", function() require("hover").hover_switch("previous") end, {desc = "hover.nvim (previous source)"})
      -- vim.keymap.set("n", "<C-n>", function() require("hover").hover_switch("next") end, {desc = "hover.nvim (next source)"})

      -- Mouse support
      vim.keymap.set('n', '<MouseMove>', require('hover').hover_mouse, { desc = "hover.nvim (mouse)" })
      vim.o.mousemoveevent = true
    end
  },
  -- PG: trouble.nvim for diagnostics
  {
    "trouble.nvim",
    for_cat = "general.extra",
    opts = {}, -- for default options, refer to the configuration section for custom setup.
    cmd = { "Trouble" },
    keys = {
      {
        "<leader>xx",
        "<cmd>Trouble diagnostics toggle<cr>",
        mode = "n",
        desc = "Diagnostics (Trouble)",
      },
      {
        "<leader>xX",
        "<cmd>Trouble diagnostics toggle filter.buf=0<cr>",
        mode = "n",
        desc = "Buffer Diagnostics (Trouble)",
      },
      {
        "<leader>cs",
        "<cmd>Trouble symbols toggle focus=false<cr>",
        mode = "n",
        desc = "Symbols (Trouble)",
      },
      {
        "<leader>cl",
        "<cmd>Trouble lsp toggle focus=false win.position=right<cr>",
        mode = "n",
        desc = "LSP Definitions / references / ... (Trouble)",
      },
      {
        "<leader>xL",
        "<cmd>Trouble loclist toggle<cr>",
        mode = "n",
        desc = "Location List (Trouble)",
      },
      {
        "<leader>xQ",
        "<cmd>Trouble qflist toggle<cr>",
        mode = "n",
        desc = "Quickfix List (Trouble)",
      },
    },
    after = function(_)
      require("trouble").setup()
    end
  },
  -- PG: Show all workspace diagnostics
  {
    "workspace-diagnostics.nvim",
    for_cat = "general.always",
    keys = {
      {
        "<leader>wd",
        function()
          for _, client in ipairs(vim.lsp.get_clients()) do
            require("workspace-diagnostics").populate_workspace_diagnostics(client, 0)
          end
        end,
        mode = "n",
        desc = "[W]orkspace [D]iagnostics"
      }
    },
  },
  -- PG: Rust extras
  {
    -- Note: configuration in LSPs/init.lua
    "rustaceanvim",
    for_cat = "general.extra",
    cmd = { "RustLsp" },
    ft = "rust",
  },
  -- PG: Type ( and get () for free!
  {
    "nvim-autopairs",
    for_cat = "general.always",
    event = "DeferredUIEnter",
    after = function(_)
      require("nvim-autopairs").setup({
        check_ts = true,
        -- Don't add autopairs inside those treesitter nodes
        -- (e.g. inside strings)
        ts_config = {
          lua = {"string"},
          rust = {"string_literal"},
        },
      })
    end,
  },
  -- PG: Search multibuffer (editable results with context)
  {
    "ctrlsf.vim",
    for_cat = "general.extra",
    cmd = { "CtrlSF", "CtrlSFOpen", "CtrlSFToggle", },
    keys = {
      {"<leader>ff", "<Plug>CtrlSFPrompt", mode = "n", remap = true, desc = "CtrlS[F]: [F]ind"},
      {"<leader>ff", "<Plug>CtrlSFVwordPath", mode = "v", remap = true, desc = "CtrlS[F]: [F]ind selected word"},
      {"<leader>ft", "<Cmd>CtrlSFToggle<CR>", mode = "n", remap = true, desc = "CtrlS[F]: [T]oggle panel"},
    },
    after = function(_)
      -- Automatically focus on the search results
      vim.g.ctrlsf_auto_focus = { at = "start", }
      -- Show preview of each file as we walk through results
      vim.g.ctrlsf_auto_preview = true
      vim.g.ctrlsf_mapping = {
        -- Remove "o" mapping to open (use it for newline so we can edit on the buffer)
        open = "<CR>",
        openb = {},
        next = "<C-J>",
        prev = "<C-K>",
      }
    end
  },
  -- PG: Toggleterm - easy terminal window
  {
    "toggleterm.nvim",
    for_cat = "general.extra",
    cmd = { "ToggleTerm", "ToggleTermToggleAll", "TermExec", "TermSelect" },
    keys = {
      {"<leader>T", "", mode = "n", desc = "Toggle Terminal"}
    },
    after = function(_)
      local shell = vim.o.shell
      if vim.fn.executable("nu") == 1 then
        -- Don't set it to nu globally as some plugins rely on posix shell syntax
        shell = vim.fn.exepath("nu")
      end
      require("toggleterm").setup({
        open_mapping = [[<leader>T]],
        direction = "horizontal",
        on_open = function(_)
          if vim.fn.exists('&winfixbuf') > 0 then
            -- Ensure we don't replace the terminal with some other file
            vim.wo.winfixbuf = true
          end
        end,

        shell = shell,

        -- Don't check for mappings in insert mode
        -- (Lags on every space...)
        insert_mappings = false,
        terminal_mappings = false,
      })
    end
  },
  -- PG: Colored icons (for bufferline, arrow, lualine, ...)
  {
    "nvim-web-devicons",
    for_cat = "general.extra",
    event = "DeferredUIEnter",
    dep_of = {"arrow.nvim", "lualine.nvim"},
  },
  -- PG: Arrow for quick navigation
  -- Use ';' to bookmark certain files
  -- Use 'm' to bookmark certain locations within a file
  -- TODO: Consider using harpoon 2 instead?
  {
    "arrow.nvim",
    for_cat = "general.extra",
    keys = {
      {";", "", mode = "n", desc = "Arrow File Mappings"},
      {"m", "", mode = "n", desc = "Arrow Buffer Mappings"},
    },
    after = function(_)
      require("arrow").setup({
        show_icons = true,
        leader_key = ";",  -- Prefix for per-file bookmark operations
        buffer_leader_key = "m",  -- Prefix for in-buffer bookmark operations
      })
    end,
  },
  -- PG: Search buffer facilities (similar to CtrlSF but more versatile)
  {
    "grug-far.nvim",
    for_cat = "general.extra",
    cmd = { "GrugFar" },
    keys = {
      -- Note: use <leader>S for grug-specific commands after running search
      -- Use <leader>Sc to close
      {"<leader>Sg", function() require('grug-far').open({ engine = 'ripgrep' }) end, mode = "n", desc = "Grugfar [S]earch with rip[G]rep"},
      {"<leader>Sg", function() require('grug-far').with_visual_selection({ engine = 'ripgrep' }) end, mode = "v", desc = "Grugfar [S]earch Selection with rip[G]rep"},
      {"<leader>Sa", function() require('grug-far').open({ engine = 'astgrep' }) end, mode = "n", desc = "Grugfar [S]earch with [A]st-grep"},
      {"<leader>Sa", function() require('grug-far').with_visual_selection({ engine = 'astgrep' }) end, mode = "v", desc = "Grugfar [S]earch Selection with [A]st-grep"},
      {"<leader>S/", function() require('grug-far').open({ prefills = { paths = vim.fn.expand("%") } }) end, mode = "n", desc = "Grugfar [S]earch in File"},
      {"<leader>S/", function() require('grug-far').with_visual_selection({ prefills = { paths = vim.fn.expand("%") } }) end, mode = "v", desc = "Grugfar [S]earch Selection in File"},
      {"<leader>SA", function() require('grug-far').open({ engine = 'astgrep', prefills = { paths = vim.fn.expand("%") } }) end, mode = "n", desc = "Grugfar [S]earch in File with [A]st-grep"},
      {"<leader>SA", function() require('grug-far').with_visual_selection({ engine = 'astgrep', prefills = { paths = vim.fn.expand("%") } }) end, mode = "v", desc = "Grugfar [S]earch Selection in File with [A]st-grep"},
    },
    after = function(_)
      local keymaps = require("grug-far.opts").defaultOptions.keymaps
      local newKeymaps = {}
      for name, keymap in pairs(keymaps) do
        if keymap["n"] ~= nil then
          -- Grug-specific keybinds go under <leader>S
          newKeymaps[name] = { n = string.gsub(keymap.n, "<localleader>", "<leader>S"), }
        end
      end

      -- Now, our own overrides
      newKeymaps = vim.tbl_extend("force", newKeymaps, {
        -- Shows the 'rg ...' invocation, exotic enough for uppercase X
        toggleShowCommand = { n = "<leader>SX" },
        -- Use 'p' for preview instead of 'i'
        -- We will use 'i' to toggle case (in)sensitivity
        previewLocation = { n = "<leader>Sp" },
      })

      -- Custom keybindings in the search multibuffer
      vim.api.nvim_create_autocmd('FileType', {
        group = vim.api.nvim_create_augroup('grug-far-keymap', { clear = true }),
        pattern = { 'grug-far' },
        callback = function()
          -- Jump back to search input by hitting shift up in normal mode:
          vim.keymap.set('n', '<S-Up>', function()
            vim.api.nvim_win_set_cursor(vim.fn.bufwinid(0), { 2, 0 })
          end, { buffer = true, desc = "grug-far: Return to search input" })

          -- Hit Ctrl-Enter to close search.
          vim.keymap.set('n', '<C-enter>', '<leader>So<leader>Sc', { buffer = true, desc = "grug-far: Open and close search" })

          -- Hit <leader>Si to toggle case insensitivity.
          vim.keymap.set("n", "<leader>Si", function()
            local state = unpack(require('grug-far').toggle_flags({ '-s' }))
            vim.notify('grug-far: toggled -s (--case-sensitive) ' .. (state and 'ON' or 'OFF'))
          end, { buffer = true, desc = "grug-far: Toggle case (in)sensitivity" })

          -- Hit <leader>SC to toggle "-C 0" (no context).
          vim.keymap.set("n", "<leader>SC", function()
            local state = unpack(require('grug-far').toggle_flags({ '-C 0' }))
            vim.notify('grug-far: toggled -C 0 (no line context) ' .. (state and 'ON' or 'OFF'))
          end, { buffer = true, desc = "grug-far: Toggle line context (-C 0)" })

          -- Hit <leader>SF to toggle "--fixed-strings" (no regex)
          vim.keymap.set("n", "<leader>SF", function()
            local state = unpack(require('grug-far').toggle_flags({ '--fixed-strings' }))
            vim.notify('grug-far: toggled --fixed-strings (no regex) ' .. (state and 'ON' or 'OFF'))
          end, { buffer = true, desc = "grug-far: Toggle literal (non-regex) search (--fixed-strings)" })
        end,
      })

      require("grug-far").setup({
        keymaps = newKeymaps,
        engines = {
          ripgrep = {
            -- Always add some context lines around the results
            -- Start with case insensitivity by default
            extraArgs = "-C 5 -i",
            placeholders = {
              -- Since we start with ignore-case (-i), suggest the opposite, as well as -C 0
              flags = "e.g. --help --case-sensitive (-s) -C 0 (remove context) --replace= (empty replace) --multiline (-U)",
            },
          },
        },
      })
    end
  },
  -- PG: Guess how to much to indent file by based on contents.
  {
    "guess-indent.nvim",
    for_cat = "general.extra",
    cmd = { "GuessIndent" },
    event = "DeferredUIEnter",
    after = function(_)
      require("guess-indent").setup({
        filetype_exclude = {
          "netrw",
          "tutor",
          "NvimTree",
          "grug-far",
          "ctrlsf",
        }
      })
    end
  },
  {
    "flash.nvim",
    for_cat = "general.extra",
    keys = {
      { "s", mode = { "n" }, function() require("flash").jump() end, desc = "Flash" },
      { "S", mode = { "n" }, function() require("flash").treesitter() end, desc = "Flash Treesitter" },
      { "z", mode = { "x", "o" }, function() require("flash").jump() end, desc = "Flash" },
      { "Z", mode = { "x", "o" }, function() require("flash").treesitter() end, desc = "Flash Treesitter" },
      { "r", mode = "o", function() require("flash").remote() end, desc = "Remote Flash" },
      { "R", mode = { "o", "x" }, function() require("flash").treesitter_search() end, desc = "Treesitter Search" },
      { "<leader>zs", mode = "n", function() require("flash").toggle() end, desc = "Toggle Flash Search" },
    },
  },
  {
    "lazydev.nvim",
    for_cat = 'neonixdev',
    cmd = { "LazyDev" },
    ft = "lua",
    after = function(plugin)
      require('lazydev').setup({
        library = {
          { words = { "nixCats" }, path = (require('nixCats').nixCatsPath or "") .. '/lua' },
        },
      })
    end,
  },
  {
    "markdown-preview.nvim",
    -- NOTE: for_cat is a custom handler that just sets enabled value for us,
    -- based on result of nixCats('cat.name') and allows us to set a different default if we wish
    -- it is defined in luaUtils template in lua/nixCatsUtils/lzUtils.lua
    -- you could replace this with enabled = nixCats('cat.name') == true
    -- if you didnt care to set a different default for when not using nix than the default you already set
    for_cat = 'general.markdown',
    cmd = { "MarkdownPreview", "MarkdownPreviewStop", "MarkdownPreviewToggle", },
    ft = "markdown",
    keys = {
      {"<leader>mp", "<cmd>MarkdownPreview <CR>", mode = {"n"}, noremap = true, desc = "markdown preview"},
      {"<leader>ms", "<cmd>MarkdownPreviewStop <CR>", mode = {"n"}, noremap = true, desc = "markdown preview stop"},
      {"<leader>mt", "<cmd>MarkdownPreviewToggle <CR>", mode = {"n"}, noremap = true, desc = "markdown preview toggle"},
    },
    before = function(plugin)
      vim.g.mkdp_auto_close = 0
    end,
  },
  {
    "undotree",
    for_cat = 'general.extra',
    cmd = { "UndotreeToggle", "UndotreeHide", "UndotreeShow", "UndotreeFocus", "UndotreePersistUndo", },
    keys = { { "<leader>U", "<cmd>UndotreeToggle<CR>", mode = { "n" }, desc = "Undo Tree" }, },
    before = function(_)
      vim.g.undotree_WindowLayout = 1
      vim.g.undotree_SplitWidth = 40
    end,
  },
  {
    "comment.nvim",
    for_cat = 'general.extra',
    event = "DeferredUIEnter",
    after = function(plugin)
      require('Comment').setup()
    end,
  },
  {
    "indent-blankline.nvim",
    for_cat = 'general.extra',
    event = "DeferredUIEnter",
    after = function(plugin)
      require("ibl").setup()
    end,
  },
  {
    "nvim-surround",
    for_cat = 'general.always',
    event = "DeferredUIEnter",
    -- keys = "",
    after = function(plugin)
      -- PG: Remove whitespace around delimiters
      -- (See https://github.com/kylechui/nvim-surround/issues/122)
      require('nvim-surround').setup({
        surrounds = {
          ["("] = false,
          ["["] = false,
          ["{"] = false,
          ["<"] = false,
        },
        aliases = {
          ["("] = ")",
          ["["] = "]",
          ["{"] = "}",
          ["<"] = ">",
        },
      })
    end,
  },
  {
    "vim-startuptime",
    for_cat = 'general.extra',
    cmd = { "StartupTime" },
    before = function(_)
      vim.g.startuptime_event_width = 0
      vim.g.startuptime_tries = 10
      vim.g.startuptime_exe_path = nixCats.packageBinPath
    end,
  },
  {
    "fidget.nvim",
    for_cat = 'general.extra',
    event = "DeferredUIEnter",
    -- keys = "",
    after = function(plugin)
      require('fidget').setup({})
    end,
  },
  -- {
  --   "hlargs",
  --   for_cat = 'general.extra',
  --   event = "DeferredUIEnter",
  --   -- keys = "",
  --   dep_of = { "nvim-lspconfig" },
  --   after = function(plugin)
  --     require('hlargs').setup {
  --       color = '#32a88f',
  --     }
  --     vim.cmd([[hi clear @lsp.type.parameter]])
  --     vim.cmd([[hi link @lsp.type.parameter Hlargs]])
  --   end,
  -- },
  {
    "lualine.nvim",
    for_cat = 'general.always',
    -- cmd = { "" },
    event = "DeferredUIEnter",
    -- ft = "",
    -- keys = "",
    -- colorscheme = "",
    after = function (plugin)

      require('lualine').setup({
        options = {
          icons_enabled = true,  -- PG: Show filetype and other icons!
          theme = colorschemeName,
          component_separators = '|',
          section_separators = '',
          globalstatus = true, -- PG: Don't show a status for each buffer
        },
        sections = {
          lualine_b = {
            'branch',
            'diff',
            -- PG: Update diagnostic icons
            {
              'diagnostics',
              symbols = {error = ' ', warn = ' ', info = ' ', hint = '󰌵 '},
            },
          },
          lualine_c = {
            {
              'filename', path = 1, status = true,
            },
          },
        },
        inactive_sections = {
          lualine_b = {
            {
              'filename', path = 3, status = true,
            },
          },
          lualine_x = {'filetype'},
        },
        tabline = {
          lualine_a = { 'buffers' },
          -- if you use lualine-lsp-progress, I have mine here instead of fidget
          -- lualine_b = { 'lsp_progress', },
          lualine_z = { 'tabs' }
        },
        extensions = {"nvim-tree", "toggleterm"}, -- PG: custom status line for nvim-tree and toggleterm
      })
    end,
  },
  {
    "gitsigns.nvim",
    for_cat = 'general.always',
    dep_of = "nvim-scrollbar",  -- PG: Ensure scrollbar is initialized after gitsigns
    event = "DeferredUIEnter",
    -- cmd = { "" },
    -- ft = "",
    -- keys = "",
    -- colorscheme = "",
    after = function (plugin)
      require('gitsigns').setup({
        -- See `:help gitsigns.txt`
        signs = {
          add = { text = '+' },
          change = { text = '~' },
          delete = { text = '_' },
          topdelete = { text = '‾' },
          changedelete = { text = '~' },
        },
        on_attach = function(bufnr)
          local gs = package.loaded.gitsigns

          local function map(mode, l, r, opts)
            opts = opts or {}
            opts.buffer = bufnr
            vim.keymap.set(mode, l, r, opts)
          end

          -- Navigation
          map({ 'n', 'v' }, ']c', function()
            if vim.wo.diff then
              return ']c'
            end
            vim.schedule(function()
              gs.next_hunk()
            end)
            return '<Ignore>'
          end, { expr = true, desc = 'Jump to next hunk' })

          map({ 'n', 'v' }, '[c', function()
            if vim.wo.diff then
              return '[c'
            end
            vim.schedule(function()
              gs.prev_hunk()
            end)
            return '<Ignore>'
          end, { expr = true, desc = 'Jump to previous hunk' })

          -- Actions
          -- visual mode
          map('v', '<leader>hs', function()
            gs.stage_hunk { vim.fn.line '.', vim.fn.line 'v' }
          end, { desc = 'stage git hunk' })
          map('v', '<leader>hr', function()
            gs.reset_hunk { vim.fn.line '.', vim.fn.line 'v' }
          end, { desc = 'reset git hunk' })
          -- normal mode
          map('n', '<leader>gs', gs.stage_hunk, { desc = 'git stage hunk' })
          map('n', '<leader>gr', gs.reset_hunk, { desc = 'git reset hunk' })
          map('n', '<leader>gS', gs.stage_buffer, { desc = 'git Stage buffer' })
          map('n', '<leader>gu', gs.undo_stage_hunk, { desc = 'undo stage hunk' })
          map('n', '<leader>gR', gs.reset_buffer, { desc = 'git Reset buffer' })
          map('n', '<leader>gp', gs.preview_hunk, { desc = 'preview git hunk' })
          map('n', '<leader>gb', function()
            gs.blame_line { full = false }
          end, { desc = 'git blame line' })
          map('n', '<leader>gd', gs.diffthis, { desc = 'git diff against index' })
          map('n', '<leader>gD', function()
            gs.diffthis '~'
          end, { desc = 'git diff against last commit' })

          -- Toggles
          map('n', '<leader>gtb', gs.toggle_current_line_blame, { desc = 'toggle git blame line' })
          map('n', '<leader>gtd', gs.toggle_deleted, { desc = 'toggle git show deleted' })

          -- Text object
          map({ 'o', 'x' }, 'ih', ':<C-U>Gitsigns select_hunk<CR>', { desc = 'select git hunk' })
        end,
      })
      vim.cmd([[hi GitSignsAdd guifg=#04de21]])
      vim.cmd([[hi GitSignsChange guifg=#83fce6]])
      vim.cmd([[hi GitSignsDelete guifg=#fa2525]])
    end,
  },
  {
    "which-key.nvim",
    for_cat = 'general.extra',
    -- cmd = { "" },
    event = "DeferredUIEnter",
    -- ft = "",
    -- keys = "",
    -- colorscheme = "",
    after = function (plugin)
      require('which-key').setup({
      })
      require('which-key').add {
        { "<leader><leader>", group = "buffer commands" },
        { "<leader><leader>_", hidden = true },
        { "<leader>c", group = "[c]ode" },
        { "<leader>c_", hidden = true },
        { "<leader>d", group = "[d]ocument" },
        { "<leader>d_", hidden = true },
        { "<leader>g", group = "[g]it" },
        { "<leader>g_", hidden = true },
        { "<leader>m", group = "[m]arkdown" },
        { "<leader>m_", hidden = true },
        { "<leader>r", group = "[r]ename" },
        { "<leader>r_", hidden = true },
        { "<leader>s", group = "[s]earch" },
        { "<leader>s_", hidden = true },
        { "<leader>t", group = "[t]oggles" },
        { "<leader>t_", hidden = true },
        { "<leader>w", group = "[w]orkspace" },
        { "<leader>w_", hidden = true },
      }
    end,
  },
}
