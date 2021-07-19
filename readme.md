<div align="center">
<h1 align="center">
  zest.nvim
</h1>
a pinch of lisp for a tangy init.lua
</div>
<br>

An opinionated macro library that aims to streamline the process of configuring [neovim](https://neovim.io/) with [fennel](https://fennel-lang.org/), a lisp that compiles to lua.

The plugin can be installed on its own or together with [aniseed](https://github.com/Olical/aniseed).

<b>WIP</b> If you have any feedback or ideas on how to improve zest, please share them with me! You can reach me at @tsbohc on the aniseed discord.

For an up-to-date full config example, see my [dotfiles](https://github.com/tsbohc/.garden/tree/master/etc/nvim.d/fnl).

## usage

Install with your favourite package manager.

- require all macros
```clojure
(require-macros :zest.macros)
```
- or import macros selectively, with renaming support
```clojure
(import-macros {:def-autocmd au-} :zest.macros)
```

## macros
In each example, the top block contains the fennel code written in the configuration, while the bottom one shows the lua code that neovim will execute.

<b>NOTE</b> macros below are currently available under `zest.new-macros`, but require some globals:
```clojure
(tset _G :ZEST (or _G.ZEST {:keymap  {} :autocmd {}}))
```
Will fix this later today.

## options

### set-option
- todo

### get-option
- todo

## keymaps

### def-keymap

- map literals:
```clojure
(def-keymap :H [nv] "0")
```
```lua
do
  vim.api.nvim_set_keymap("n", "H", "0", {noremap = true})
  vim.api.nvim_set_keymap("v", "H", "0", {noremap = true})
end
```

- map expressions:
```clojure
(each [_ k (ipairs [:h :j :k :l])]
  (def-keymap (.. "<c-" k ">") [n] (.. "<c-w>" k)))
```
```lua
for _, k in ipairs({"h", "j", "k", "l"}) do
  vim.api.nvim_set_keymap("n", ("<c-" .. k .. ">"), ("<c-w>" .. k), {noremap = true})
end
```

- map pairs:
```clojure
(def-keymap [n]
  {:<c-h> "<c-w>h"
   :<c-n> "<c-w>j"
   :<c-e> "<c-w>k"
   :<c-i> "<c-w>l"})
```
```lua
do
  vim.api.nvim_set_keymap("n", "<c-h>", "<c-w>h", {noremap = true})
  vim.api.nvim_set_keymap("n", "<c-i>", "<c-w>l", {noremap = true})
  vim.api.nvim_set_keymap("n", "<c-e>", "<c-w>k", {noremap = true})
  vim.api.nvim_set_keymap("n", "<c-n>", "<c-w>j", {noremap = true})
end
```

- to disable `noremap`, include `:remap` after the specifying modes

### def-keymap-fn
- define a function and map it to a key

```clojure
(def-keymap-fn :<c-m> [n]
  (print "hello from fennel!"))
```
```lua
do
  local function _0_()
    return print("hello from fennel!")
  end
  _G["ZEST"]["keymap"]["__3C_c_2D_m_3E_"] = _0_
  vim.api.nvim_set_keymap("n", "<c-m>", (":call v:lua.ZEST.keymap." .. "__3C_c_2D_m_3E_" .. "()<cr>"), {noremap = true})
end
```

- define an expression as a function

```clojure
(def-keymap-fn :e [nv :expr]
  (if (> vim.v.count 0) "k" "gk"))
```
```lua
do
  local function _0_()
    if (vim.v.count > 0) then
      return "k"
    else
      return "gk"
    end
  end
  _G["ZEST"]["keymap"]["_k"] = _0_
  vim.api.nvim_set_keymap("n", "k", ("v:lua.ZEST.keymap." .. "_k" .. "()"), {expr = true, noremap = true})
  vim.api.nvim_set_keymap("v", "k", ("v:lua.ZEST.keymap." .. "_k" .. "()"), {expr = true, noremap = true})
end
```

## autocommands

### def-augroup
- define an augroup with `autocmd!`

```clojure
(def-augroup :my-augroup)
```
```lua
do
  vim.api.nvim_command(("augroup " .. "my-augroup"))
  vim.api.nvim_command("autocmd!")
  vim.api.nvim_command("augroup END")
end
```

### def-autocmd
- define an autocommand

```clojure
(def-autocmd "*" [VimResized] "wincmd =")
```
```lua
vim.api.nvim_command(("au " .. "VimResized" .. " " .. "*" .. " " .. "wincmd ="))
```

### def-autocmd-fn
- define a function and bind it as an autocommand

```clojure
(def-augroup :restore-position
  (def-autocmd-fn "*" [BufReadPost]
    (when (and (> (vim.fn.line "'\"") 1)
               (<= (vim.fn.line "'\"") (vim.fn.line "$")))
      (vim.cmd "normal! g'\""))))
```
```lua
do
  vim.api.nvim_command(("augroup " .. "restore-position"))
  vim.api.nvim_command("autocmd!")
  do
    local function _0_()
      if ((vim.fn.line("'\"") > 1) and (vim.fn.line("'\"") <= vim.fn.line("$"))) then
        return vim.cmd("normal! g'\"")
      end
    end
    _G["ZEST"]["autocmd"]["_6_2E_7758292924808e_2B_141_5F__2A__5F_BufReadPost"] = _0_
    vim.api.nvim_command("au BufReadPost * :call v:lua.ZEST.autocmd._6_2E_7758292924808e_2B_141_5F__2A__5F_BufReadPost()")
  end
  vim.api.nvim_command("augroup END")
end
```

### def-augroup-dirty
- define an augroup without `autocmd!`

```clojure
(def-augroup-dirty :my-dirty-augroup)
```
```lua
do
  vim.api.nvim_command(("augroup " .. "my-dirty-augroup"))
  vim.api.nvim_command("augroup END")
end
```

<hr>

# soon be deprecated:

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

- map keys to functions
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

### g-
- set global variable
```clojure
(g- gruvbox_contrast_dark :soft)
```
```lua
vim.g["gruvbox_contrast_dark"] = "soft"
```

### utils
- *exec-* execute an ex command
- *norm-* execute normal mode commands
- *eval-* evaluate a vimscript expression
- *viml-* evaluate a block of vimscript

```clojure
(ki- [x] :* (fn []
  (norm- "gvy")
  (exec- (.. "/" (eval- "@\"")))
  (norm- "N")))
```
```lua
local function _0_()
  vim.api.nvim_command("norm! gvy")
  vim.api.nvim_command(("/" .. vim.api.nvim_eval("@\"")))
  return vim.api.nvim_command("norm! N")
end
require("zest.bind")("x", "*", _0_, {noremap = true})
```

### misc
- *colo-* set current colorscheme
```clojure
(colo- :limestone)
```
```lua
vim.api.nvim_exec("colo limestone", true)
```
- *lead-* mapleader
```clojure
(lead- " ")
```
```lua
vim.g["mapleader"] = " "
```
