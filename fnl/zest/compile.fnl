; filesystem helpers

(local fs {})

(fn fs.read [path]
  (with-open [file (assert (io.open path "r"))]
    (file:read "*a")))

(fn fs.write [path content]
  (with-open [file (assert (io.open path "w"))]
    (file:write content)))

(fn fs.dirname [path]
  (path:match "(.*[/\\])"))

; compiler

(local state
  {:fennel false})

(fn get-rtp []
  "get rtp entries containing /fnl and /lua formatted for fennel.path"
  (var r "")
  (let [fnl-suffix "/fnl/?.fnl"
        lua-suffix "/lua/?.lua"
        rtp (.. vim.o.runtimepath ",")]
    (each [e (rtp:gmatch "(.-),")]
      (let [f (.. e "/fnl")
            l (.. e "/lua")]
        (if (= 1 (vim.fn.isdirectory f))
          (set r (.. r ";" (.. e fnl-suffix)))
          (= 1 (vim.fn.isdirectory l))
          (set r (.. r ";" (.. e lua-suffix))))))
    (r:sub 2)))

(fn load-fennel []
  "initialise zest compiler"
  (let [fennel (require :zest.fennel)]
    (set fennel.path (.. (get-rtp) ";" fennel.path))
    (set state.fennel fennel)
    (vim.api.nvim_command ":redraw")
    (vim.api.nvim_echo [[" zest " "Search"] [" " "None"]
                        ["initialise compiler" "None"]]
                       false {})
    state.fennel))

(local M {})

(fn M.compile []
  "compile current file"
  (local source (vim.fn.expand "%:p"))
  (when (not (source:find "macros.fnl$"))
    (let [fennel (or state.fennel (load-fennel))
          fnl-path (vim.fn.resolve _G._zest.config.source)
          lua-path (vim.fn.resolve _G._zest.config.target)
          target (string.gsub (string.gsub source ".fnl$" ".lua") fnl-path lua-path) ]
      (when _G._zest.config.verbose-compiler
        (vim.api.nvim_command ":redraw")
        (vim.api.nvim_echo [[" zest " "Search"] [" " "None"]
                            [(vim.fn.expand "%:t") "None"]
                            [" => " "Comment"]
                            [(target:gsub vim.env.HOME "~") "None"]]
                           false {}))
      (match [fnl-path lua-path]
        [x y]
        (do
          (vim.fn.mkdir (fs.dirname target) :p)
          (fs.write target (fennel.compileString (fs.read source))))
        [nil x]
        (print "<zest> invalid source path!")
        [x nil]
        (print "<zest> invalid target path!")))))

(setmetatable M {:__call (fn [_ ...] (M.compile ...))})

M
