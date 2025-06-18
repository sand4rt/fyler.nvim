<div  align="center">
  <h1>Fyler.nvim</h1>
  <p>A flowless neovim file manager</p>
</div>

<p align="center">
  <img alt="License" src="https://img.shields.io/github/license/A7Lavinraj/fyler.nvim?style=for-the-badge&logo=starship&color=ee999f&logoColor=D9E0EE&labelColor=302D41" />
  <img alt="Stars" src="https://img.shields.io/github/stars/A7Lavinraj/fyler.nvim?style=for-the-badge&logo=starship&color=c69ff5&logoColor=D9E0EE&labelColor=302D41" />
</p>

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
    {
      default_explorer = false,
      close_on_select = true,
      views = {
        file_tree = {
          width = 0.8,
          height = 0.8,
          kind = "float",
          border = "single",
        },
      },
      mappings = {
        file_tree = {
          n = {
            ["q"] = "CloseView",
            ["<CR>"] = "Select",
          },
        },
      },
    }
  ```
</details>

## Usage

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
- [ ] GIT integration (BASIC)
- [ ] GIT integration (ADVANCE)
- [ ] Track current buffer
- [ ] Fuzzy finding
- [ ] LSP integration
- [ ] SSH integration

## Similar plugins

- [oil.nvim](https://github.com/stevearc/oil.nvim)
- [mini.files](https://github.com/echasnovski/mini.files)

## Codebase inspiration

- [neogit](https://github.com/NeogitOrg/neogit)

## Special thanks to all contributors!

<a href="https://github.com/A7Lavinraj/fyler.nvim/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=A7Lavinraj/fyler.nvim" />
</a>
