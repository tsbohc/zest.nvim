<div align="center">
<h1 align="center">
  zest.nvim
</h1>
a pinch of lisp for a tangy init.lua
</div>
<br>

An opinionated macro library that aims to streamline the process of configuring [neovim](https://neovim.io/) with [fennel](https://fennel-lang.org/), a lisp that compiles to lua.

For a full config example, see my [dotfiles](https://github.com/tsbohc/.garden/tree/master/etc/nvim.d/fnl). The plugin can be installed on its own or together with [aniseed](https://github.com/Olical/aniseed).

### features

- Syntactically sweet macros inspired by viml
- Macros that seamlessly integrate lua functions into viml
- Almost everything is done at compile time
- Can be configured to recompile the config on `BufWritePost`
- No startup penalty

<b>WIP</b> If you have any feedback or ideas on how to improve zest, please share them with me! You can reach me in an issue or at @tsbohc on the [conjure discord](conjure.fun/discord).

## usage

- Install with your favourite package manager
```clojure
(use :tsbohc/zest.nvim)
```
- Run `zest.setup` to initialise `_G._zest` before using any of the macros

```clojure
(let [zest (require :zest)]
  (zest.setup))
```

- Import the macros you wish to use in the current file, aliasing them as you like
```clojure
(import-macros
  {:opt-prepend opt^} :zest.macros)
```

Without aniseed, zest can be configured to mirror the `source` directory tree to `target`. When a relevant file is saved, zest will display a message and recompile it.

Unless configured, zest will not initialise its compiler.

<details>
  <summary>Show an example of standalone configuration</summary>

  <br>

  ```clojure
  (let [zest (require :zest)
        h vim.env.HOME]
    (zest.setup
      {:target (.. h "/.garden/etc/nvim.d/lua")
       :source (.. h "/.garden/etc/nvim.d/fnl")
       :verbose-compiler true
       :disable-compiler false}))
  ```

</details>

# macros
In each example, the top block contains the fennel code written in the configuration, while the bottom one shows the lua code that neovim will execute.

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
    local ZEST_ID_0_ = "_60_99_45_109_62_110_"
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
    local ZEST_ID_0_ = "_107_110_118_"
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
(def-autocmd [:BufNewFile :BufRead] [:*.html :*.xml]
  "setlocal nowrap")
```
```lua
local _0_
if (type({"BufNewFile", "BufRead"}) == "string") then
  _0_ = {"BufNewFile", "BufRead"}
else
  _0_ = table.concat({"BufNewFile", "BufRead"}, ",")
end
local _2_
if (type({"*.html", "*.xml"}) == "string") then
  _2_ = {"*.html", "*.xml"}
else
  _2_ = table.concat({"*.html", "*.xml"}, ",")
end
vim.api.nvim_command(("au " .. _0_ .. " " .. _2_ .. " " .. "setlocal nowrap"))
```

### def-autocmd-fn

- Define a function and bind it as an autocommand

```clojure
(def-augroup :restore-position
  (def-autocmd-fn :BufReadPost "*"
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
    vim.api.nvim_command(("au " .. "BufReadPost" .. " " .. "*" .. " " .. ZEST_RHS_0_))
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

## notes

### a tale of two macros

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

### user commands

There isn't a more concise way to define user commands than using straight up strings. I don't see much benefit in passing individual arguments with s-expressions or lists: it's far too verbose.

I would suggest doing something like this:

```clojure
(fn def-command [s f]
  (let [s (.. ":command " s)]
    (vim.cmd (if f (vlua-format s f) s))))

(def-command
  "-nargs=* Mycmd :call %s(<f-args>)"
  Mycmd)
```

### text objects

When it comes to defining text objects, they can be considered fancy keymaps. Here're the definitions of `inner line` and `around line`:

```clojure
(def-keymap :il [xo :silent]
  (string.format ":<c-u>normal! %s<cr>"
    "g_v^"))
```
```clojure
(def-keymap :al [xo :silent]
  (vlua-format ":<c-u>call %s()<cr>"
    (fn [] (vim.cmd "normal! $v0"))))
```

### text operators

Text operators are the fanciest of keymaps. Here's a minimal example:

```clojure
(fn def-operator [k f]
  (let [v-lua (vlua f)]
    (def-keymap k [n :silent] (string.format ":set operatorfunc=%s<cr>g@" v-lua))
    (def-keymap k [v :silent] (string.format ":<c-u>call %s(visualmode())<cr>" v-lua))
    (def-keymap (.. k k) [n :silent] (string.format ":<c-u>call %s(v:count1)<cr>" v-lua))))

(def-operator :q
  (fn [x] (print x))
```

### complex autocmds

It's debatable, but with `def-autocmd` and `def-autocmd-fn` I've made the decision in favour of syntactic sweetness. More often than not I see autocmds defined in place, with a concrete set of parameters.

If you need to pass events to the definition or create complex autocmds, use `vlua`:

```clojure
(vim.cmd
  (vlua-format
    (.. ":autocmd " ponder " * <buffer=42> ++once :call %s()")
    print-answer))
```

# thanks

- [bakpakin](https://github.com/bakpakin) for [fennel](https://github.com/bakpakin/Fennel), a wonderful dialect for a wonderful language
- [Olical](https://github.com/Olical) for [aniseed](https://github.com/Olical/aniseed) and being awesome
- [ElKowar](https://github.com/elkowar) for sharing his thoughts and his discord status
- [Hauleth](https://old.reddit.com/user/Hauleth) for this [post](https://old.reddit.com/r/neovim/comments/n5dczu/when_vim_and_lisp_are_your_love/), which sparked my interest in fennel

> zest embeds `fennel.lua`. I do not claim any ownership over this file
