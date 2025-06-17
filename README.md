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

## Features status
- [x] Basic file operations (CREATE, DELETE, MOVE)
- [x] User command to change behaviour on startup
- [x] Hijack NETRW
- [x] GIT integration (BASIC)
- [ ] GIT integration (ADVANCE)
- [ ] Track current buffer
- [ ] Fuzzy finding
- [ ] LSP integration
- [ ] SSH integration

<h2>Want to try now?</h2>

```lua
{
  "A7Lavinraj/fyler.nvim",
  dependencies = { "echasnovski/mini.icons" },
  opts = {}
}
```

<h2>Default options</h2>

```lua
{
  close_on_open = true,
  default_explorer = false,
  window_config = {
    width = 0.3,
    split = 'right',
  },
  window_options = {
    number = true,
    relativenumber = true,
  },
  view_config = {
    git_status = {
      enable = true,
    },
  },
}
```

## Contributors

<a href="https://github.com/A7Lavinraj/fyler.nvim/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=A7Lavinraj/fyler.nvim" />
</a>
