(local compile {})

; loading fennel takes huge a toll on the startup time, like 100ms+
; let's require it only when we need to recompile

; NOTE: this module should probably have no dependencies

; write logging to a preview buffer below?

(local state {:initialised? false})

(local fnl-path "/home/sean/.garden/etc/nvim.d/fnl/")
(local lua-path "/home/sean/.config/nvim/lua/")

(local zest-fnl-path "/home/sean/code/zest/fnl/zest/")
(local zest-lua-path "/home/sean/code/zest/lua/zest/")

; create hooks

(vim.cmd "augroup testgroup")
(vim.cmd "autocmd!")
(vim.cmd (.. "autocmd BufWritePost " fnl-path "*.fnl :lua require('zest')(vim.fn.expand('%:p'), '" fnl-path "', '" lua-path "')"))
(vim.cmd (.. "autocmd BufWritePost " zest-fnl-path "*.fnl :lua require('zest')(vim.fn.expand('%:p'), '" zest-fnl-path "', '" zest-lua-path "')"))
(vim.cmd "augroup end")

; mini fs

(local fs {})

(fn fs.dirname [path]
  (path:match "(.*[/\\])"))

(fn fs.mkdir [path]
  (os.execute (.. "mkdir -p " path)))

(fn fs.read [path]
  (with-open [file (assert (io.open path "r"))]
    (file:read "*a")))

(fn fs.write [path content]
  (with-open [file (assert (io.open path "w"))]
    (file:write content)))

(fn fs.isdir [path]
  (let [file (io.open path "r")]
    (if (= nil file)
      false
      (do
        (file:close)
        true))))

; compile

(fn get-rtp []
  "get rtp entries containing /fnl and /lua formatted for fennel.path"
  (var r "")
  (let [fnl-suffix "/fnl/?.fnl"
        lua-suffix "/lua/?.lua"
        rtp (.. vim.o.runtimepath ",")]
    (each [e (rtp:gmatch "(.-),")]
      (let [f (.. e "/fnl")
            l (.. e "/lua")]
        (if (fs.isdir f)
          (set r (.. r ";" (.. e fnl-suffix)))
          (fs.isdir l)
          (set r (.. r ";" (.. e lua-suffix))))))
    (r:sub 2)))

(fn init-compiler []
  (let [fennel (require :zest.fennel)]
    (when (not state.initialised?)
      (print "zest: initiate compiler")
      (set fennel.path (.. (get-rtp) ";" fennel.path))
      (tset state :initialised? true))
    fennel))

(fn compile.compile [source relative-to target-path]
  (when (not (source:find "macros"))
    (let [fennel (init-compiler)
          relative (source:gsub relative-to "")
          target (.. target-path (relative:gsub ".fnl$" ".lua"))]
      (fs.mkdir (fs.dirname target))
      (fs.write target (fennel.compileString (fs.read source))))))

(setmetatable
  compile {:__call (fn [_ ...] (compile.compile ...))})

compile
