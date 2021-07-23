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
(import-macros {:opt-prepend opt^} :zest.macros)
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

Macro names are intentionally quite verbose, remember that you can alias them to something much shorter.

The examples are refreshed with every change to zest and are always up to date.

### vlua

- Store a function and return its `v:lua`, excluding the parentheses

```clojure
(local v (vlua my-fn))
```
```lua
local v
do
  local ZEST_ID_0_ = ("_" .. _G._zest.v["#"])
  _G._zest["v"][ZEST_ID_0_] = __fnl_global__my_2dfn
  _G._zest["v"]["#"] = (_G._zest.v["#"] + 1)
  v = ("v:lua._zest.v." .. ZEST_ID_0_)
end
```

### vlua-format

- A `string.format` wrapper for `vlua`

```clojure
(vim.api.nvim_command
  (vlua-format
    ":com -nargs=* Mycmd :call %s(<f-args>)"
    (fn [...]
      (print ...))))
```
```lua
local function _0_(...)
  local ZEST_ID_0_ = ("_" .. _G._zest.v["#"])
  local function _1_(...)
    return print(...)
  end
  _G._zest["v"][ZEST_ID_0_] = _1_
  _G._zest["v"]["#"] = (_G._zest.v["#"] + 1)
  return ("v:lua._zest.v." .. ZEST_ID_0_)
end
vim.api.nvim_command(string.format(":com -nargs=* Mycmd :call %s(<f-args>)", _0_(...)))
```

## options

- A complete `vim.opt` wrapper

```clojure
(opt-local-append completeopt ["menuone" "noselect"])
```
```lua
do end (vim.opt_local.completeopt):append({"menuone", "noselect"})
```

<details>
  <summary>Full list of <code>opt-</code> macros</summary>

  <br>

  ```
  opt-set      opt-local-set      opt-global-set
  opt-get      opt-local-get      opt-global-get
  opt-append   opt-local-append   opt-global-append
  opt-prepend  opt-local-prepend  opt-global-prepend
  opt-remove   opt-local-remove   opt-global-remove
  ```

</details>

## keymaps

### def-keymap

- Map literals

```clojure
(def-keymap :H [nv] "0")
```
```lua
do
  vim.api.nvim_set_keymap("n", "H", "0", {noremap = true})
  vim.api.nvim_set_keymap("v", "H", "0", {noremap = true})
end
```

- Map lua expressions

```clojure
(each [_ k (ipairs [:h :j :k :l])]
  (def-keymap (.. "<c-" k ">") [n] (.. "<c-w>" k)))
```
```lua
for _, k in ipairs({"h", "j", "k", "l"}) do
  vim.api.nvim_set_keymap("n", ("<c-" .. k .. ">"), ("<c-w>" .. k), {noremap = true})
end
```

- Map pairs

```clojure
(def-keymap [n]
  {:<ScrollWheelUp>   "<c-y>"
   :<ScrollWheelDown> "<c-e>"})
```
```lua
vim.api.nvim_set_keymap("n", "<ScrollWheelUp>", "<c-y>", {noremap = true})
vim.api.nvim_set_keymap("n", "<ScrollWheelDown>", "<c-e>", {noremap = true})
```

To disable `noremap`, include `:remap` after the modes.

### def-keymap-fn

- Define a function and map it to a key

```clojure
(def-keymap-fn :<c-m> [n]
  (print "hello from fennel!"))
```
```lua
do
  local ZEST_VLUA_0_
  do
    local ZEST_ID_0_ = "_60_99_45_109_62_"
    local function _0_()
      return print("hello from fennel!")
    end
    _G._zest["keymap"][ZEST_ID_0_] = _0_
    ZEST_VLUA_0_ = ("v:lua._zest.keymap." .. ZEST_ID_0_)
  end
  local ZEST_RHS_0_ = string.format(":call %s()<cr>", ZEST_VLUA_0_)
  for ZEST_M_0_ in string.gmatch("n", ".") do
    vim.api.nvim_set_keymap(ZEST_M_0_, "<c-m>", ZEST_RHS_0_, {noremap = true})
  end
end
```

- Define an expression as a function

```clojure
(def-keymap-fn :k [nv :expr]
  (if (> vim.v.count 0) "k" "gk"))
```
```lua
do
  local ZEST_VLUA_0_
  do
    local ZEST_ID_0_ = "_107_"
    local function _0_()
      if (vim.v.count > 0) then
        return "k"
      else
        return "gk"
      end
    end
    _G._zest["keymap"][ZEST_ID_0_] = _0_
    ZEST_VLUA_0_ = ("v:lua._zest.keymap." .. ZEST_ID_0_)
  end
  local ZEST_RHS_0_ = string.format("%s()", ZEST_VLUA_0_)
  for ZEST_M_0_ in string.gmatch("nv", ".") do
    vim.api.nvim_set_keymap(ZEST_M_0_, "k", ZEST_RHS_0_, {expr = true, noremap = true})
  end
end
```

## autocommands

### def-augroup

- Define an augroup with `autocmd!` included

```clojure
(def-augroup :my-augroup)
```
```lua
do
  vim.api.nvim_command(("augroup " .. "my-augroup"))
  vim.api.nvim_command("autocmd!")
  do
  end
  vim.api.nvim_command("augroup END")
end
```

### def-autocmd

- Define an autocommand

```clojure
(def-autocmd "*" [VimResized] "wincmd =")
```
```lua
vim.api.nvim_command(("au " .. "VimResized" .. " " .. "*" .. " " .. "wincmd ="))
```

### def-autocmd-fn

- Define a function and bind it as an autocommand

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
    local ZEST_VLUA_0_
    do
      local ZEST_ID_0_ = ("_" .. _G._zest.autocmd["#"])
      local function _0_()
        if ((vim.fn.line("'\"") > 1) and (vim.fn.line("'\"") <= vim.fn.line("$"))) then
          return vim.cmd("normal! g'\"")
        end
      end
      _G._zest["autocmd"][ZEST_ID_0_] = _0_
      _G._zest["autocmd"]["#"] = (_G._zest.autocmd["#"] + 1)
      ZEST_VLUA_0_ = ("v:lua._zest.autocmd." .. ZEST_ID_0_)
    end
    local ZEST_RHS_0_ = string.format(":call %s()", ZEST_VLUA_0_)
    vim.api.nvim_command(("au BufReadPost " .. "*" .. " " .. ZEST_RHS_0_))
  end
  vim.api.nvim_command("augroup END")
end
```

### def-augroup-dirty

- Define an augroup without `autocmd!`

```clojure
(def-augroup-dirty :my-dirty-augroup)
```
```lua
do
  vim.api.nvim_command(("augroup " .. "my-dirty-augroup"))
  do
  end
  vim.api.nvim_command("augroup END")
end
```

## textobjects

### def-textobject

- Define a custom text object as a normal mode string

```clojure
(def-textobject :il "g_v^")
```
```lua
do
  local ZEST_RHS_0_ = (":<c-u>norm! " .. "g_v^" .. "<cr>")
  vim.api.nvim_set_keymap("x", "il", ZEST_RHS_0_, {noremap = true, silent = true})
  vim.api.nvim_set_keymap("o", "il", ZEST_RHS_0_, {noremap = true, silent = true})
end
```

### def-textobject-fn

- Define a custom text object as a function

```clojure
(def-textobject-fn :al
  (vim.cmd "norm! $v0"))
```
```lua
do
  local ZEST_VLUA_0_
  do
    local ZEST_ID_0_ = "_97_108_"
    local function _0_()
      return vim.cmd("norm! $v0")
    end
    _G._zest["textobject"][ZEST_ID_0_] = _0_
    ZEST_VLUA_0_ = ("v:lua._zest.textobject." .. ZEST_ID_0_)
  end
  local ZEST_RHS_0_ = string.format(":<c-u>call %s()<cr>", ZEST_VLUA_0_)
  vim.api.nvim_set_keymap("x", "al", ZEST_RHS_0_, {noremap = true, silent = true})
  vim.api.nvim_set_keymap("o", "al", ZEST_RHS_0_, {noremap = true, silent = true})
end
```

## faq

### why are there two of each macro?

At compile time, there is no good way of knowing if a variable contains a function or a string. I think so, at least (enlighten me!). This means that the type of the argument has to be supplied to the macro explicitly.

This is the reason for the having both `def-keymap` and `def-keymap-fn`, for example.

That said, `def-keymap` and others can accept functions if they have been wrapped in `vlua`:

```clojure
(fn my-fn []
  (print "dinosaurs"))

(def-keymap :<c-m> [n]
  (vlua-format
    ":call %s()<cr>"
    my-fn))
```

### user commands?

Currently, there isn't a more concise way to define user commands than using straight up strings. I don't see much benefit in defining individual arguments with s-expressions: it's far too verbose.

For now, I would suggest doing something like this:

```clojure
(fn def-command-fn [s f]
  (vim.api.nvim_command
    (vlua-format
      (.. ":command " s) f)))

(fn Mycmd [...]
  (print ...))

(def-cmd-fn
  "-nargs=* Mycmd :call %s(<f-args>)"
  Mycmd)
```

# thanks

- [Hauleth](https://old.reddit.com/user/Hauleth) for this [post](https://old.reddit.com/r/neovim/comments/n5dczu/when_vim_and_lisp_are_your_love/), which sparked my interest in fennel
- [Olical](https://github.com/Olical) for aniseed and being awesome
- [ElKowar](https://github.com/elkowar) for sharing his thoughts and his discord status
