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

#### with aniseed

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

#### without aniseed

When installed on its own, zest can be configured to mirror the `source` directory tree to `target`. When a relevant file is saved, zest will display a message and recompile it. 

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
{{fnl:vlua1}}
```
```lua
{{lua:vlua1}}
```

### vlua-format

- A `string.format` wrapper for `vlua`

```clojure
{{fnl:vlua-format1}}
```
```lua
{{lua:vlua-format1}}
```

## options

- A complete `vim.opt` wrapper

```clojure
{{fnl:opt}}
```
```lua
{{lua:opt}}
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
{{fnl:def-keymap1}}
```
```lua
{{lua:def-keymap1}}
```

- Map lua expressions

```clojure
{{fnl:def-keymap2}}
```
```lua
{{lua:def-keymap2}}
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
{{fnl:def-keymap-fn1}}
```
```lua
{{lua:def-keymap-fn1}}
```

- Define an expression as a function

```clojure
{{fnl:def-keymap-fn2}}
```
```lua
{{lua:def-keymap-fn2}}
```

## autocommands

### def-augroup

- Define an augroup with `autocmd!` included

```clojure
{{fnl:def-augroup1}}
```
```lua
{{lua:def-augroup1}}
```

### def-autocmd

- Define an autocommand

```clojure
{{fnl:def-autocmd1}}
```
```lua
{{lua:def-autocmd1}}
```

### def-autocmd-fn

- Define a function and bind it as an autocommand

```clojure
{{fnl:def-autocmd-fn1}}
```
```lua
{{lua:def-autocmd-fn1}}
```

### def-augroup-dirty

- Define an augroup without `autocmd!`

```clojure
{{fnl:def-augroup-dirty1}}
```
```lua
{{lua:def-augroup-dirty1}}
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
