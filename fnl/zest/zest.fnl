(local fs (require :zest.fs))
(local co (require :zest.core))

(local compile {})

(local state {:initialised? false})

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
    (when (not state.initialised?)
      (print "<zest> initialise compiler")
      (set fennel.path (.. (get-rtp) ";" fennel.path))
      (tset state :initialised? true))
    fennel))

(fn compile.compile [source relative-to target-path]
  (when (not (source:find "macros.fnl$"))
    (let [fennel (init-compiler)
          relative (source:gsub relative-to "")
          target (.. target-path (relative:gsub ".fnl$" ".lua"))]
      (vim.fn.mkdir (fs.dirname target) "p")
      (fs.write target (fennel.compileString (fs.read source))))))

(setmetatable
  compile {:__call (fn [_ ...] (compile.compile ...))})

compile
