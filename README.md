<div>
  <img
    alt="Showcase"
    src="https://github.com/user-attachments/assets/51d8d4dd-6b0a-4539-af65-84dc6714066c"
  />
  <div align="center">
    <h1>Fyler.nvim</h1>
    <table>
      <tr>
        <td>
          <strong>A file manager for <a href="https://neovim.io">Neovim</a></strong>
        </td>
      </tr>
    </table>
    <div>
      <img
        alt="License"
        src="https://img.shields.io/github/license/A7Lavinraj/fyler.nvim?style=for-the-badge&logo=starship&color=ee999f&logoColor=D9E0EE&labelColor=302D41"
      />
      <img
        alt="Stars"
        src="https://img.shields.io/github/stars/A7Lavinraj/fyler.nvim?style=for-the-badge&logo=starship&color=c69ff5&logoColor=D9E0EE&labelColor=302D41"
      />
    </div>
  </div>
</div>

## Installation

> [!IMPORTANT]
> Please be careful while choosing between `stable` and `latest` version.
>
> - `stable` branch updates on releases.
> - `stable` version documentation might be different.
> - `main` branch updates frequently(can have bugs).

### Stable version

> [!NOTE]
> Please refer to `stable` version [documentation page](https://github.com/A7Lavinraj/fyler.nvim/blob/stable/README.md). Latest version documentation might not be compatible for stable version.

<details open>
  <summary><a href="https://github.com/folke/lazy.nvim"><strong>Lazy.nvim</strong></a> (recommended)</summary>

```lua
{
  "A7Lavinraj/fyler.nvim",
  dependencies = { "echasnovski/mini.icons" },
  branch = "stable",
  opts = {}
}
```

</details>

### Latest version

<details open>
  <summary><a href="https://github.com/folke/lazy.nvim"><strong>Lazy.nvim</strong></a> (recommended)</summary>

You can use default setup with `mini.icons`

```lua
{
  "A7Lavinraj/fyler.nvim",
  dependencies = { "echasnovski/mini.icons" },
  opts = {}
}
```

Or change to `nvim-web-devicons`

```lua
{
  "A7Lavinraj/fyler.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  opts = {
    icon_provider = "nvim-web-devicons",
  }
}
```

</details>

<details>
  <summary><a href="https://github.com/echasnovski/mini.deps"><strong>Mini.deps</strong></a></summary>

```lua
add({
  source = 'A7Lavinraj/fyler.nvim',
  depends = { 'echasnovski/mini.icons' },
})
```

</details>

<details open>
  <summary>(Default configuration)</summary>

```lua
local defaults = {
  -- Changes icon provider
  icon_provider = "mini-icons",
  -- Changes mappings for associated view
  mappings = {
    explorer = {
      ["q"] = "CloseView",
      ["<CR>"] = "Select",
    },
    confirm = {
      ["y"] = "Confirm",
      ["n"] = "Discard",
    },
  },
  -- Changes builtin highlight groups
  on_highlights = function() end,
  -- Changes configuration for associated view
  views = {
    confirm = {
      win = {
        -- Changes window border
        border = "single",
        -- Changes buffer options
        buf_opts = {
          buflisted = false,
          modifiable = false,
        },
        -- Changes window kind
        kind = "float",
        -- Changes window kind preset
        kind_presets = {
          float = {
            height = 0.4,
            width = 0.5,
          },
          split_above = {
            height = 0.5,
          },
          split_above_all = {
            height = 0.5,
          },
          split_below = {
            height = 0.5,
          },
          split_below_all = {
            height = 0.5,
          },
          split_left = {
            width = 0.5,
          },
          split_left_most = {
            width = 0.5,
          },
          split_right = {
            width = 0.5,
          },
          split_right_most = {
            width = 0.5,
          },
        },
        -- Changes window options
        win_opts = {
          winhighlight = "Normal:Normal,FloatBorder:FloatBorder,FloatTitle:FloatTitle",
          wrap = false,
        },
      },
    },
    explorer = {
      -- Changes explorer closing behaviour when a file get selected
      close_on_select = true,
      -- Changes explorer behaviour to auto confirm simple edits
      confirm_simple = false,
      -- Changes explorer behaviour to hijack NETRW
      default_explorer = false,
      -- Changes git statuses visibility
      git_status = true,
      -- Changes Indentation marker properties
      indentscope = {
        enabled = true,
        group = "FylerIndentMarker",
        marker = "│",
      },
      win = {
      -- Changes window border
        border = "single",
      -- Changes buffer options
        buf_opts = {
          buflisted = false,
          buftype = "acwrite",
          expandtab = true,
          filetype = "fyler",
          shiftwidth = 2,
          syntax = "fyler",
        },
      -- Changes window kind
        kind = "float",
      -- Changes window kind preset
        kind_presets = {
          float = {
            height = 0.7,
            width = 0.7,
          },
          split_above = {
            height = 0.7,
          },
          split_above_all = {
            height = 0.7,
          },
          split_below = {
            height = 0.7,
          },
          split_below_all = {
            height = 0.7,
          },
          split_left = {
            width = 0.3,
          },
          split_left_most = {
            width = 0.3,
          },
          split_right = {
            width = 0.3,
          },
          split_right_most = {
            width = 0.3,
          },
        },
      -- Changes window options
        win_opts = {
          concealcursor = "nvic",
          conceallevel = 3,
          cursorline = true,
          number = true,
          relativenumber = true,
          winhighlight = "Normal:Normal,FloatBorder:FloatBorder,FloatTitle:FloatTitle",
          wrap = false,
        },
      },
    },
  },
}
```

</details>

## Usage

You can either open Fyler by `Fyler` command

```vim
:Fyler             " Open with default options
:Fyler kind=<kind> " Open with specific window kind
:Fyler cwd=<path>  " Open with specific directory
```

Or using lua api

```lua
local fyler = require("fyler")

-- Open with default options
fyler.open()

-- Open with specific directory
fyler.open({ cwd = "~/" })

-- Open with specific kind
fyler.open({ cwd = "split_left_most" })
```

## TODOS

- [x] Basic file operations `CREATE | DELETE | MOVE`
- [x] User command to change behaviour on startup
- [x] Hijack NETRW
- [x] Track current buffer
- [x] GIT integration
- [x] Indentation guides
- [x] Buffer-Explorer synchronization
- [ ] File system watching
- [ ] LSP integration
- [ ] SSH integration
- [ ] Fuzzy finding

## Have problems with fyler.nvim?

1. Search for existing [issues](https://github.com/A7Lavinraj/fyler.nvim/issues)
2. If related issue is not there then open a new one

## Want to contribute to this project?

- Please read the [CONTRIBUTING.md](https://github.com/A7Lavinraj/fyler.nvim/blob/main/CONTRIBUTING.md)

## Similar plugins

- [oil.nvim](https://github.com/stevearc/oil.nvim)
- [mini.files](https://github.com/echasnovski/mini.files)

## Codebase inspiration

- [neogit](https://github.com/NeogitOrg/neogit)
- [telescope](https://github.com/nvim-telescope/telescope.nvim)

## Special thanks to all contributors

![Contributors](https://contrib.rocks/image?repo=A7Lavinraj/fyler.nvim)
