<div  align="center">
  <h1>Fyler.nvim</h1>
  <p>A modern neovim file tree which can edit your file system like a buffer</p>
</div>

<p align="center">
  <img alt="License" src="https://img.shields.io/github/license/A7Lavinraj/fyler.nvim?style=for-the-badge&logo=starship&color=ee999f&logoColor=D9E0EE&labelColor=302D41" />
  <img alt="Stars" src="https://img.shields.io/github/stars/A7Lavinraj/fyler.nvim?style=for-the-badge&logo=starship&color=c69ff5&logoColor=D9E0EE&labelColor=302D41" />
</p>

![Image](https://github.com/user-attachments/assets/cf3d7904-d5dd-4c15-94cd-eaecd38ddc1e)

> [!WARNING]
> This plugin is still under developement and not ready to use

## Installtion

### Stable version

<details open>
  <summary><a href="https://github.com/folke/lazy.nvim">lazy.nvim</a> (recommended)</summary>

  ```lua
  {
    "A7Lavinraj/fyler.nvim",
    dependencies = { "echasnovski/mini.icons" },
    commit = "d87e4281e18712361f82a07f9fca71957244ef33",
    opts = {} -- check the default options in the README.md
  }
  ```
</details>

### Latest version

<details open>
  <summary><a href="https://github.com/folke/lazy.nvim">lazy.nvim</a> (recommended)</summary>

  ```lua
  {
    "A7Lavinraj/fyler.nvim",
    dependencies = { "echasnovski/mini.icons" },
    opts = {} -- check the default options in the README.md
  }
  ```
</details>

<details>
  <summary><a href="https://github.com/echasnovski/mini.deps">mini.deps</a></summary>

  ```lua
  add({
    source = 'A7Lavinraj/fyler.nvim',
    depends = { 'echasnovski/mini.icons' },
  })
  ```
</details>

<details>
  <summary>(Default configuration)</summary>

  ```lua
  local defaults = {
    -- NETRW Hijacking:
    -- The plugin will replace most of the netrw command
    -- By default this option is disable to avoid any incompatibility
    default_explorer = false,

    -- Close open file:
    -- This enable user to close fyler window on opening a file
    close_on_select = true,

    -- Views configuration:
    -- Every view config contains following options to be customized
    -- `width` a number in [0, 1]
    -- `height` a number in [0, 1]
    -- `kind` could be 'float', 'split:left', 'split:above', 'split:right', 'split:below'
    -- `border` could be 'bold', 'double', 'none', 'rounded', 'shadow', 'single', 'solid'
    views = {
      file_tree = {
        width = 0.8,
        height = 0.8,
        kind = "float",
        border = "single",
      },
    },

    -- Mappings:
    -- mappings can be customized by action names which are local to thier view
    mappings = {
      -- For `file_tree` actions checkout following link:
      -- https://github.com/A7Lavinraj/fyler.nvim/blob/main/lua/fyler/views/file_tree/actions.lua
      file_tree = {
        n = {
          ["q"] = "CloseView",
          ["<CR>"] = "Select",
          ["<C-CR>"] = "SelectRecursive",
        },
      },
    },
  }
  ```
</details>

## Usage

https://github.com/user-attachments/assets/ea71ff58-1c5c-4cda-b54e-f845d70f5184

There is user command `Fyler` is optionally accepts two options:

- kind
- cwd

```lua
-- Open fyler with specific window kind
:Fyler kind=split:left
:Fyler kind=split:right
:Fyler kind=split:above
:Fyler kind=split:below

-- Open fyler with specific directory
:Fyler cwd=/home/user/.config/nvim
```

## TODOS

- [x] Basic file operations (CREATE, DELETE, MOVE)
- [x] User command to change behaviour on startup
- [x] Hijack NETRW
- [x] Track current buffer
- [ ] GIT integration (BASIC)
- [ ] GIT integration (ADVANCE)
- [ ] Fuzzy finding
- [ ] LSP integration
- [ ] SSH integration

## Have problems with fyler.nvim?

1. Search for existing [issues](https://github.com/A7Lavinraj/fyler.nvim/issues)
2. If related issue is not there then open a new one

## Want to contribute to this project?

- Please read the [CONTRIBUTING.md](https://github.com/A7Lavinraj/fyler.nvim/blob/main/CONTRIBUTING.md) to start

## Similar plugins

- [oil.nvim](https://github.com/stevearc/oil.nvim)
- [mini.files](https://github.com/echasnovski/mini.files)

## Codebase inspiration

- [neogit](https://github.com/NeogitOrg/neogit)

## Special thanks to all contributors!

<a href="https://github.com/A7Lavinraj/fyler.nvim/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=A7Lavinraj/fyler.nvim" />
</a>
