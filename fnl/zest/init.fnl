(local fs (require :zest.fs))
(local co (require :zest.core))

(local M {})

(var initialised? false)

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

(fn init-compiler []
  "initialise zest compiler"
  (let [fennel (require :zest.fennel)]
    (when (not initialised?)
      (print "<zest> initialise compiler")
      (set fennel.path (.. (get-rtp) ";" fennel.path))
      (set initialised? true))
    fennel))

(fn M.compile [source relative-to target-path]
  (when (not (source:find "macros.fnl$"))
    (let [fennel (init-compiler)
          relative (source:gsub relative-to "")
          target (.. target-path (relative:gsub ".fnl$" ".lua"))]
      (vim.fn.mkdir (fs.dirname target) "p")
      (fs.write target (fennel.compileString (fs.read source))))))

(setmetatable M {:__call (fn [_ ...] (M.compile ...))})

M
