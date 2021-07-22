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
- Almost everything is done at compile time using macros
- Lazy-loads the fennel compiler on `BufWritePost`
- Automatically recompiles `fnl/` to `lua/`

<b>WIP</b> If you have any feedback or ideas on how to improve zest, please share them with me! You can reach me in an issue or at @tsbohc on the [conjure discord](conjure.fun/discord).

For a full config example, see my [dotfiles](https://github.com/tsbohc/.garden/tree/master/etc/nvim.d/fnl).

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

### setup

By default, zest will mirror the `stdpath/fnl` directory tree (or one that is symlinked to that path) to `stdpath/lua`. When a relevant file is saved, zest will display a message and recompile it.

```clojure
(z.setup
  {:source (vim.fn.resolve (.. (vim.fn.stdpath :config) "/fnl"))
   :target (vim.fn.resolve (.. (vim.fn.stdpath :config) "/lua"))
   :verbose-compiler true
   :disable-compiler false})
```

# macros
In each example, the top block contains the fennel code written in the configuration, while the bottom one shows the lua code that neovim will execute.

### v-lua

- store a function and return its `v:lua`, excluding the parentheses

```clojure
(local v (v-lua my-fn))
```
```lua
local v
do
  local id_0_ = ("_" .. _G._zest.v["#"])
  _G._zest["v"][id_0_] = my_fn
  _G._zest["v"]["#"] = (_G._zest.v["#"] + 1)
  v = ("v:lua._zest.v." .. id_0_)
end
```

### v-lua-format

- a `string.format` wrapper for `v-lua`

```clojure
(vim.api.nvim_command
  (v-lua-format
    ":com -nargs=* Mycmd :call %s(<f-args>)"
    (fn [...]
      (print ...))))
```
```lua
local function _1_(...)
  local id_0_ = ("_" .. _G._zest.v["#"])
  local function _2_(f_args)
    return print(f_args)
  end
  _G._zest["v"][id_0_] = _2_
  _G._zest["v"]["#"] = (_G._zest.v["#"] + 1)
  return ("v:lua._zest.v." .. id_0_)
end
vim.api.nvim_command(string.format(":com -nargs=* Mycmd :call %s(<f-args>)", _1_(...)))
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
vim.api.nvim_set_keymap("n", "H", "0", {noremap = true})
vim.api.nvim_set_keymap("v", "H", "0", {noremap = true})
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
  {:<ScrollWheelUp>   "<c-y>"
   :<ScrollWheelDown> "<c-e>"})
```
```lua
vim.api.nvim_set_keymap("n", "<ScrollWheelUp>", "<c-y>", {noremap = true})
vim.api.nvim_set_keymap("n", "<ScrollWheelDown>", "<c-e>", {noremap = true})
```

### def-keymap-fn
- define a function and map it to a key

```clojure
(def-keymap-fn :<c-m> [n]
  (print "hello from fennel!"))
```
```lua
local v_0_
do
  local id_0_ = "_60_99_45_109_62_"
  local function _2_()
    return print("hello from fennel!")
  end
  _G._zest["keymap"][id_0_] = _2_
  v_0_ = ("v:lua._zest.keymap." .. id_0_)
end
local ts_0_ = string.format(":call %s()<cr>", v_0_)
for m_0_ in string.gmatch("n", ".") do
  vim.api.nvim_set_keymap(m_0_, "<c-m>", ts_0_, {noremap = true})
end
```

- define an expression as a function

```clojure
(def-keymap-fn :k [nv :expr]
  (if (> vim.v.count 0) "k" "gk"))
```
```lua
local v_0_
do
  local id_0_ = "_107_"
  local function _2_()
    if (vim.v.count > 0) then
      return "k"
    else
      return "gk"
    end
  end
  _G._zest["keymap"][id_0_] = _2_
  v_0_ = ("v:lua._zest.keymap." .. id_0_)
end
local ts_0_ = string.format("%s()", v_0_)
for m_0_ in string.gmatch("nv", ".") do
  vim.api.nvim_set_keymap(m_0_, "k", ts_0_, {expr = true, noremap = true})
end
```

## autocommands

### def-augroup
- define an augroup with `autocmd!` included

```clojure
(def-augroup :my-augroup)
```
```lua
vim.api.nvim_command(("augroup " .. "my-augroup"))
vim.api.nvim_command("autocmd!")
vim.api.nvim_command("augroup END")
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
vim.api.nvim_command(("augroup " .. "restore-position"))
vim.api.nvim_command("autocmd!")
do
  local v_0_
  do
    local id_0_ = ("_" .. _G._zest.autocmd["#"])
    local function _2_()
      if ((vim.fn.line("'\"") > 1) and (vim.fn.line("'\"") <= vim.fn.line("$"))) then
        return vim.cmd("normal! g'\"")
      end
    end
    _G._zest["autocmd"][id_0_] = _2_
    _G._zest["autocmd"]["#"] = (_G._zest.autocmd["#"] + 1)
    v_0_ = ("v:lua._zest.autocmd." .. id_0_)
  end
  local ts_0_ = string.format(":call %s()", v_0_)
  vim.api.nvim_command(("au BufReadPost " .. "*" .. " " .. ts_0_))
end
vim.api.nvim_command("augroup END")
```

### def-augroup-dirty
- define an augroup without `autocmd!`

```clojure
(def-augroup-dirty :my-dirty-augroup)
```
```lua
vim.api.nvim_command(("augroup " .. "my-dirty-augroup"))
vim.api.nvim_command("augroup END")
```

# thanks

- [Olical](https://github.com/Olical) for sparking my interest in lisps
- [ElKowar](https://github.com/elkowar) for sharing his thoughts and his discord status
