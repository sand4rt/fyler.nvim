import pynvim


def misc() -> None:
    nvim = pynvim.attach(
        "child", argv=["/usr/bin/env", "nvim", "--embed", "--headless", "--clean"]
    )

    nvim.exec_lua(
        "vim.opt.runtimepath:prepend(vim.fn.getcwd())"
        "vim.opt.runtimepath:prepend(vim.fs.joinpath(vim.fn.getcwd(), '.tests/repos/mini.icons'))"
        "vim.opt.runtimepath:prepend(vim.fs.joinpath(vim.fn.getcwd(), '.tests/repos/nvim-web-devicons'))"
    )
    nvim.exec_lua("require('fyler').setup()")
    nvim.exec_lua("require('fyler').open()")

    assert nvim.current.buffer.options.get("filetype") == "fyler"


def spec(Test):
    return Test(run=misc)
