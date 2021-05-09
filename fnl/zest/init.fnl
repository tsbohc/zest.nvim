(local fs (require :zest.fs))
(local co (require :zest.core))

(local compile {})

; log to a preview buffer below?

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
  "initialise fennel compiler"
  (let [fennel (require :zest.fennel)]
    (when (not state.initialised?)
      (print "zest: initiate compiler")
      (set fennel.path (.. (get-rtp) ";" fennel.path))
      (tset state :initialised? true))
    fennel))

(fn compile.compile [source relative-to target-path]
  (let [except [:se- :ki-]]
    (when (not (co.has? except (source:sub -7 -5)))
      (let [fennel (init-compiler)
            relative (source:gsub relative-to "")
            target (.. target-path (relative:gsub ".fnl$" ".lua"))]
        (fs.mkdir (fs.dirname target))
        (fs.write target (fennel.compileString (fs.read source)))))))

(setmetatable
  compile {:__call (fn [_ ...] (compile.compile ...))})

compile
