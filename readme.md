<div align="center">
<h1 align="center">
  zest.nvim
</h1>
a pinch of lisp for a tangy init.lua
</div>
<br>

An opinionated macro library that aims to streamline the process of configuring [neovim](https://neovim.io/) with [fennel](https://fennel-lang.org/), a lisp that compiles to lua.

Whenever possible, zest outputs code that consists of bare neovim api calls, falling back to functions if runtime processing is unavoidable. Though not by a significant amount, this can potentially reduce startup time.

The plugin can be installed on its own or together with [aniseed](https://github.com/Olical/aniseed).

**WIP:** not ready for general use, but feedback is very welcome!

## macros
Below are a few examples of what is possible with zest.

In each one, the top block contains fennel code written in the configuration, while the bottom one shows the lua code that neovim will execute.

### se-
- viml-esque set option

```clojure
(se- encoding "utf-8")
(se- synmaxcol 256)
(se- number)
(se- nowrap)
```
```lua
vim.api.nvim_set_option("encoding", "utf-8")
vim.api.nvim_buf_set_option(0, "synmaxcol", 256)
vim.api.nvim_win_set_option(0, "number", true)
vim.api.nvim_win_set_option(0, "wrap", false)
```
- *note:* some window options, such as `expandtab`, are considered buffer scoped in the api, meaning they will only be set for the current buffer. this will be fixed after neovim's 0.5 release.

### li-
- map keys literally
```clojure
(li- [nv] <ScrollWheelUp> <c-y>)
```
```lua
do
  vim.api.nvim_set_keymap("n", "<ScrollWheelUp>", "<c-y>", {noremap = true}),
  vim.api.nvim_set_keymap("v", "<ScrollWheelUp>", "<c-y>", {noremap = true})
end
```

### ki-
- map keys by reference
```clojure
(each [_ k (ipairs [:h :j :k :l])]
  (ki- [n] (.. "<c-" k ">") (.. "<c-w>" k)))
```
```lua
for _, k in ipairs({"h", "j", "k", "l"}) do
  require("zest.bind")("n", ("<c-" .. k .. ">"), ("<c-w>" .. k), {noremap = true})
end
```

- map keys to fennel functions
```clojure
(ki- [nvo :expr] :k (fn [] (if (> vim.v.count 0) :k :gk)))
```
```lua
local function _0_()
  if (vim.v.count > 0) then
    return "k"
  else
    return "gk"
  end
end
require("zest.bind")("nvo", "k", _0_, {expr = true, noremap = true})
```

### no-
- execute normal mode commands
```clojure
(no- dd)
```
```lua
vim.api.nvim_command("norm! dd")
```
