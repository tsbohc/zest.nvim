<div align="center">
<h1 align="center">
  zest.nvim
</h1>
a pinch of lisp for a tangy init.lua
</div>
<br>

An opinionated macro library that aims to streamline the process of configuring [neovim](https://neovim.io/) with [fennel](https://fennel-lang.org/), a lisp that compiles to lua.

The plugin can be installed on its own or together with [aniseed](https://github.com/Olical/aniseed).

### features

- Virtually no startup penalty: <0.1ms
- Everything is done at compile time using macros
- Automatically recompiles `fnl/` to `lua/`
- Fennel compiler is lazy-loaded on `BufWritePost`

<b>WIP</b> If you have any feedback or ideas on how to improve zest, please share them with me! You can reach me in an issue or at @tsbohc on the [conjure discord](conjure.fun/discord).

## usage

- Install with your favourite package manager
```clojure
(use :tsbohc/zest.nvim)
(let [z (require :zest)] (z.setup))
```

- Import macros, renaming them as you wish
```clojure
(import-macros {:zest-macro my-alias} :zest.macros)
```

For a full config example, see my [dotfiles](https://github.com/tsbohc/.garden/tree/master/etc/nvim.d/fnl).

# macros
In each example, the top block contains the fennel code written in the configuration, while the bottom one shows the lua code that neovim will execute.

### v-lua

- store a function and return its `v:lua`

```clojure
(local v (v-lua my-fn))
```
```lua
local v
do
  local n_0_ = _G._zest.v.__count
  local id_0_ = ("_" .. n_0_)
  _G._zest.v["__count"] = (n_0_ + 1)
  _G._zest.v[id_0_] = my_fn
  v = ("v:lua._zest.v." .. id_0_)
end
```

### v-lua-format

- a `string.format` wrapper for `v-lua`

```clojure
(vim.api.nvim_command
  (v-lua-format
    ":com -nargs=* Mycmd :call %s(<f-args>)"
    (fn [f-args]
      (print f-args))))
```
```lua
local function _0_(...)
  local n_0_ = _G._zest.v.__count
  local id_0_ = ("_" .. n_0_)
  _G._zest.v["__count"] = (n_0_ + 1)
  local function _1_(f_args)
    return print(f_args)
  end
  _G._zest.v[id_0_] = _1_
  return ("v:lua._zest.v." .. id_0_)
end
vim.api.nvim_command(string.format(":com -nargs=* Mycmd :call %s(<f-args>)", _0_(...)))
```

## options

### set-option
- todo

### get-option
- todo

## keymaps

### def-keymap
- to disable `noremap`, include `:remap` after the modes

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

- map lua expressions:
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
  _G["_zest"]["keymap"]["__3C_c_2D_m_3E_"] = _0_
  vim.api.nvim_set_keymap("n", "<c-m>", (":call v:lua._zest.keymap." .. "__3C_c_2D_m_3E_" .. "()<cr>"), {noremap = true})
end
```

- define an expression as a function

```clojure
(def-keymap-fn :k [nv :expr]
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
  _G["_zest"]["keymap"]["_k"] = _0_
  vim.api.nvim_set_keymap("n", "k", ("v:lua._zest.keymap." .. "_k" .. "()"), {expr = true, noremap = true})
  vim.api.nvim_set_keymap("v", "k", ("v:lua._zest.keymap." .. "_k" .. "()"), {expr = true, noremap = true})
end
```

## autocommands

### def-augroup
- define an augroup with `autocmd!` included

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
    _G["_zest"]["autocmd"]["_au_0"] = _0_
    vim.api.nvim_command(("au " .. "BufReadPost" .. " " .. "*" .. " " .. ":call v:lua._zest.autocmd._au_0()"))
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

# thanks

- [Olical](https://github.com/Olical) for sparking my interest in lisps.
- [ElKowar](https://github.com/elkowar) for sharing his thoughts and his discord status.
