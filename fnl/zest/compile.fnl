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
    (print "<zest> initialise compiler")
    (set fennel.path (.. (get-rtp) ";" fennel.path))
    (set state.fennel fennel)
    state.fennel))

(local M {})

(fn M.compile []
  "compile current file"
  (local source (vim.fn.expand "%:p"))
  (when (not (source:find "macros.fnl$"))
    (let [fennel (or state.fennel (load-fennel))
          fnl-path (vim.fn.resolve (.. (vim.fn.stdpath :config) "/fnl"))
          lua-path (vim.fn.resolve (.. (vim.fn.stdpath :config) "/lua"))
          target (string.gsub (string.gsub source ".fnl$" ".lua") fnl-path lua-path) ]
      (vim.fn.mkdir (fs.dirname target) :p)
      (fs.write target (fennel.compileString (fs.read source))))))

(setmetatable M {:__call (fn [_ ...] (M.compile ...))})

M
