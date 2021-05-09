# zest

Macro wizardry for configuring nvim in fennel. Provides compile time macros that have no impact on startup time.

#### WIP!!

Not ready for general use! Many features are missing, and existing ones are subject to change!

## features

Macros currently implemented in draft states:

#### se-

```clojure
(se- encoding "utf-8")
(se- synmaxcol 256)
(se- number)
(se- nowrap)
```
Compiles to:
```lua
vim.api.nvim_set_option("encoding", "utf-8")
vim.api.nvim_buf_set_option(0, "synmaxcol", 256)
vim.api.nvim_win_set_option(0, "number", true)
vim.api.nvim_win_set_option(0, "wrap", false)
```

#### ki-

```clojure
(ki- [n] U <c-r>)
(ki- [n] <c-m> ":echo 'woo'<cr>")
(ki- [nvo expr] :j (if (> vim.v.count 0) :j :gj))
```
Compiles to:
```lua
for m_0_ in string.gmatch("n", ".") do
  vim.api.nvim_set_keymap(m_0_, "U", "<c-r>", {noremap = true})
end
for m_0_ in string.gmatch("n", ".") do
  vim.api.nvim_set_keymap(m_0_, "<c-m>", ":echo 'woo'<cr>", {noremap = true})
end
local function _0_()
  if (vim.v.count > 0) then
    return "j"
  else
    return "gj"
  end
end
_G["__map_1"] = _0_
for m_0_ in string.gmatch("nvo", ".") do
  vim.api.nvim_set_keymap(m_0_, "j", "v:lua.__map_1()", {expr = true, noremap = true})
end
```
