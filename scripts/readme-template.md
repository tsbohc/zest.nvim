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
{{fnl:vlua1}}
```
```lua
{{lua:vlua1}}
```

### vlua-format

- A `string.format` wrapper for `vlua`

```clojure
{{fnl:vluaformat1}}
```
```lua
{{lua:vluaformat1}}
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

## textobjects

### def-textobject

- Define a custom text object as a normal mode string

```clojure
{{fnl:def-textobject1}}
```
```lua
{{lua:def-textobject1}}
```

### def-textobject-fn

- Define a custom text object as a function

```clojure
{{fnl:def-textobject-fn1}}
```
```lua
{{lua:def-textobject-fn1}}
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
