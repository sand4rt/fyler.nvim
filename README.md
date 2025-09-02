<div>
  <div align="center">
    <br/>
    <br/>
    <br/>
    <img
      width="250"
      alt="fyler-logo"
      src="https://github.com/user-attachments/assets/24838a97-e3d0-4451-ae69-433f52f816a1"
    />
    <br/>
    <br/>
    <br/>
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
  <h4 align="center">
    <a href="https://youtube.com/playlist?list=PLE5gu3yOYmtiTiC1J3BysrcormCt_eWuq&si=L6yEiJI7rNuCp5cy">Live Streams</a>
    ·
    <a href="https://github.com/A7Lavinraj/fyler.nvim/wiki">Wiki Page</a>
  </h4>
  <img
    alt="Showcase"
    src="https://github.com/user-attachments/assets/51d8d4dd-6b0a-4539-af65-84dc6714066c"
  />
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
  dependencies = { "nvim-mini/mini.icons" },
  branch = "stable",
  opts = {}
}
```

</details>

<details>
  <summary><a href="https://github.com/nvim-mini/mini.deps"><strong>Mini.deps</strong></a></summary>

```lua
add({
  source = "A7Lavinraj/fyler.nvim",
  depends = { "nvim-mini/mini.icons" },
  checkout = "stable",
})
```

</details>

### Latest version

<details open>
  <summary><a href="https://github.com/folke/lazy.nvim"><strong>Lazy.nvim</strong></a> (recommended)</summary>

You can use default setup with `mini.icons`

```lua
{
  "A7Lavinraj/fyler.nvim",
  dependencies = { "nvim-mini/mini.icons" },
  ---@type FylerConfig
  opts = {}
}
```

Or change to `nvim-web-devicons`

```lua
{
  "A7Lavinraj/fyler.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  ---@type FylerConfig
  opts = { icon_provider = "nvim_web_devicons" }
}
```

</details>

<details>
  <summary><a href="https://github.com/nvim-mini/mini.deps"><strong>Mini.deps</strong></a></summary>

```lua
add({
  source = "A7Lavinraj/fyler.nvim",
  depends = { "nvim-mini/mini.icons" },
})
```

```lua
add({
  source = "A7Lavinraj/fyler.nvim",
  depends = { "nvim-tree/nvim-web-devicons" },
})
```

</details>

<details open>
  <summary>(Default configuration)</summary>

```lua
local defaults = {
  hooks = {
    on_delete = nil, -- function(path) end
    on_rename = nil, -- function(src_path, dst_path) end
    on_highlight = nil -- function(hl_groups, palette) end
  },
  -- Changes icon provider
  icon_provider = "mini_icons",
  -- Changes mappings for associated view
  mappings = {
    ["q"] = "CloseView",
    ["<CR>"] = "Select",
    ["<C-t>"] = "SelectTab",
    ["|"] = "SelectVSplit",
    ["-"] = "SelectSplit",
    ["^"] = "GotoParent",
    ["="] = "GotoCwd",
    ["."] = "GotoNode",
    ["#"] = "CollapseAll",
  },
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
  -- Auto current buffer tracking
  track_current_buffer = true,
  win = {
    -- Changes window border
    border = "single",
    -- Changes buffer options
    buf_opts = {
      -- buffer options
    },
    -- Changes window kind
    kind = "replace",
    -- Changes window kind preset
    kind_presets = {
      -- values can be "(0,1]rel" or "{1...}abs"

      -- <preset_name> = {
      --   height = "",
      --   width = "",
      --   top = "",
      --   left = ""
      -- }

      -- replace = {},
    },
    -- Changes window options
    win_opts = {
      -- window options
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
:Fyler dir=<path>  " Open with specific directory
```

Or using lua api

```lua
local fyler = require("fyler")

-- Open with default options
fyler.open()

-- Open with specific directory
fyler.open({ dir = "~/" })

-- Open with specific kind
fyler.open({ kind = "split_left_most" })
```

## TODOS

- [x] Basic operations `CREATE | DELETE | MOVE | COPY`
- [x] GIT integration
- [x] Indentation guides
- [x] LSP integration
- [x] NETRW Hijacking
- [x] Public APIs
- [x] Track current buffer
- [x] User command
- [ ] File system watching
- [ ] Fuzzy finding
- [ ] SSH integration

## Have problems with fyler.nvim?

1. Search for existing [issues](https://github.com/A7Lavinraj/fyler.nvim/issues)
2. If related issue is not there then open a new one

## Want to contribute to this project?

- Please read the [CONTRIBUTING.md](https://github.com/A7Lavinraj/fyler.nvim/blob/main/CONTRIBUTING.md)

## Similar plugins

- [mini.files](https://github.com/nvim-mini/mini.files)
- [oil.nvim](https://github.com/stevearc/oil.nvim)

## Codebase inspiration

- [mini.nvim](https://github.com/nvim-telescope/telescope.nvim)
- [neogit](https://github.com/NeogitOrg/neogit)
- [plenary.nvim](https://github.com/nvim-telescope/telescope.nvim)
- [snacks.rename](https://github.com/folke/snacks.nvim/blob/main/docs/rename.md)
- [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim)

<div align="center">
  <h2>Special thanks to all contributors</h2>
  <a href="https://github.com/A7Lavinraj/fyler.nvim/graphs/contributors">
    <img src="https://contrib.rocks/image?repo=A7Lavinraj/fyler.nvim" alt="Contributors" />
  </a>
</div>
