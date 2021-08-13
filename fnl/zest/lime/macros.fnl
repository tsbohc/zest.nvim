; TODO
; maybe i can get the filename somehow still? on the seq metatable?

(local fennel (require :zest.fennel))
(local lime (require :zest.lime.lime)) ; for some reason init.fnl was not being picked up as :zest.lime

(fn hasfn? [x] (= (?. x 1 1) :hashfn))
(fn fn? [x] (= (?. x 1 1) :fn))
(fn partial? [x] (= (?. x 1 1) :partial))
(fn capitalised? [s] (string.match (s:sub 1 1) "%u"))

(fn zsym [...]
  "batch prefixed sym wrapper"
  (let [out []]
    (each [_ s (ipairs [...])]
      (table.insert out (gensym (.. "zest_" s))))
    (unpack out)))

(fn _zf [f]
  "prepare a function for binding"
  (let [f (if (fennel.sequence? f)
            `(fn [] ,(unpack f))
            f)]
    (if (or (fn? f)
              (hasfn? f)
              (partial? f)
              (and (fennel.sym? f)
                   (capitalised? (tostring f))))
      f)))

; {{{ literal? and old scall
;(fn literal? [x]
;  "check if 'x' is safe to evaluate a compile time"
;  (if (= x nil)
;    true
;    (if (fennel.sym? x)
;      false
;      (if (or (= (type x) :string)
;              (= (type x) :number))
;        true
;        (if (fennel.sequence? x)
;          (do
;            (each [_ v (ipairs x)]
;              (if (not (literal? v))
;                (lua "return false")))
;            true)
;          false)))))

;(fn scall [f ...]
;  "safely call a lime function in compile or run time"
;  (var safe? true)
;  (each [_ x (ipairs [...])]
;    (if (not (literal? x))
;      (set safe? false)))
;  (if safe?
;    ((. lime f) ...)
;    (list (sym (.. "lime." f)) ...)))
;}}}

; TODO rewrite with match
(fn lit? [x]
  (if (fennel.sym? x)
    false
    (if (fennel.list? x)
      false
      (if (fennel.sequence? x)
        (do
          (each [_ v (ipairs x)]
            (if (not (lit? v))
              (lua "return false")))
          true)
        (if (or (= (type x) :string)
                (= (type x) :number)
                (= x nil))
          true
          false)))))

(fn scall [f ...]
  (var safe? true)
  (each [_ x (ipairs [...])]
    (if (not (lit? x))
      (set safe? false)))
  (if safe?
    (let [res ((. lime f) ...)]
      (if (and (not (fennel.sym? res))
               (not (fennel.list? res)))
        res
        (list (sym (.. "lime." f)) ...)))
    (list (sym (.. "lime." f)) ...)))

;; keymaps

(fn _keymap-options [args]
  "convert seq of options 'args' to 'modes' string and keymap 'opts'"
  (let [modes (tostring (table.remove args 1))
        opts-xs args
        ; note: expr is preset to reduce lime calls
        opts {:noremap true
              :expr    false}]
    (each [_ o (ipairs opts-xs)]
      (if (= o :remap)
        (tset opts :noremap false)
        (tset opts o true)))
    (values modes opts)))

(fn def-keymap [args lhs rhs]
  (let [(modes opts) (_keymap-options args)
        f (_zf rhs)
        id (scall :keymap_id lhs modes)
        id-sym (gensym "zest_id")
        keymap-sym (gensym "zest_keymap")
        opts-sym (gensym "zest_opts")]
    (list 'do
          (if f (list 'local id-sym id))
          (if (and f (not (lit? id))) (list 'local opts-sym opts))
          (list 'local keymap-sym
                {
                 ;: modes
                 : f
                 : lhs
                 :opts (if (and f (not (lit? id))) opts-sym opts)
                 :rhs (if (not f)
                        rhs
                        (if (lit? id)
                          (lime.keymap_vlua id opts)
                          (list 'lime.keymap_vlua id-sym opts-sym)))})
          (if f (list 'tset '_G.zest.keymap id-sym keymap-sym))

          ; TODO investigate
          ; without this the code below disappears from the output... i have no idea
          ; only during the actual compilation too. something to do with --metadata or fennel ver?
          true

          ; TODO extract this into a separate macro, one that returns multiple statements or out seq
          (if (= modes "nvo") ; TODO a better check
            (list 'vim.api.nvim_set_keymap
                  ""
                  (sym (.. (tostring keymap-sym) ".lhs"))
                  (sym (.. (tostring keymap-sym) ".rhs"))
                  (sym (.. (tostring keymap-sym) ".opts")))
            (let [out []]
              (each [m (modes:gmatch ".")]
                (table.insert out (list 'vim.api.nvim_set_keymap
                                        m
                                        (sym (.. (tostring keymap-sym) ".lhs"))
                                        (sym (.. (tostring keymap-sym) ".rhs"))
                                        (sym (.. (tostring keymap-sym) ".opts")))))
              (unpack out))))))

; TODO extract bindings into a separate macro and unwrap if possible

(fn def-keymap-string [mod opt lhs rhs]
  (let [(mod* opt* lhs* rhs*) (zsym :mod :opt :lhs :rhs)]
    `(let [,mod* ,mod
           ,opt* ,opt
           ,lhs* ,lhs
           ,rhs* ,rhs]
       (each [m# (string.gmatch ,mod* ".")]
         (vim.api.nvim_set_keymap m# ,lhs* ,rhs* ,opt*)))))

; NB! syms go to run time, vals go to compile time
; note: we're not reusing def-keymap-string because we can't easily pass both symbols and values to another macro
(fn def-keymap-fn [mod opt lhs f]
  (let [(mod* opt* lhs* rhs* idx*) (zsym :mod :opt :lhs :rhs :idx)
        idx (scall :keymap_id lhs mod)
        rhs (match [(lit? idx) (not (fennel.sym? opt)) (. opt :expr)]
              ; TODO can probably be done without manual checks
              ; this can be considered a micro optimisation and prolly should be removed anyway
              ; human checks are error prone
              [true  true x    ] (lime.keymap_vlua idx opt)
              [false true true ] (list '.. "v:lua.zest.keymap." idx* "()")
              [false true false] (list '.. ":call v:lua.zest.keymap" idx* "()<cr>")
              _ (list 'lime.keymap_vlua idx* opt*))]
    `(let [,idx* ,idx
           ,mod* ,mod
           ,opt* ,opt
           ,lhs* ,lhs
           ,rhs* ,rhs]
       (tset _G.zest.keymap ,idx* ,f)
       (each [m# (string.gmatch ,mod* ".")]
         (vim.api.nvim_set_keymap m# ,lhs* ,rhs* ,opt*)))))

(fn def-keymap-pairs [mod opt tab]
  (let [(mod* opt* tab* lhs* rhs*) (zsym :mod :opt :tab :lhs :rhs)]
    `(let [,mod* ,mod
           ,opt* ,opt
           ,tab* ,tab]
       (each [,lhs* ,rhs* (pairs ,tab*)]
         (each [m# (string.gmatch ,mod* ".")]
           (vim.api.nvim_set_keymap m# ,lhs* ,rhs* ,opt*))))))

(fn def-keymap [args lhs rhs]
  (let [(mod opt) (_keymap-options args)
        f (_zf rhs)]
    (match [rhs f]
      [x   nil] (def-keymap-string mod opt lhs rhs)
      [x     y] (def-keymap-fn     mod opt lhs f)
      [nil nil] (def-keymap-pairs  mod opt lhs))))






; for now anyway
;(fn def-keymap-pairs [args xt]
;  (let [modes (tostring (table.remove args 1))
;        opts (let [opts {:noremap true}]
;               (each [_ o (ipairs args)]
;                 (if (= o :remap)
;                   (tset opts :noremap false)
;                   (tset opts o true)))
;               opts)]
;    (list 'do
;          (list 'local 'zest_opts# opts)
;          (let [out []]
;            (each [k v (pairs xt)]
;              (if (= modes "nvo") ; TODO a better check
;                (table.insert out `(vim.api.nvim_set_keymap "" ,k ,v zest_opts#))
;                (each [m (modes:gmatch ".")]
;                  (table.insert out `(vim.api.nvim_set_keymap ,m ,k ,v zest_opts#)))))
;            (unpack out)))))

;(fn test []
;  (list 'print (tostring (gensym "_G.zest.ya"))))
;
;(fn test []
;  (list 'local* '(one# two#) (list 'foo)))

(fn test []
  (let [a (list 'print :w)]
    (list 'print (fennel.list? a))))

;; autocmds

; def-augroup

(fn _create-augroup [dirty? name ...]
  "define a new augroup, with or without autocmd!"
  (let [definition (scall :concat (fennel.sequence "augroup" name) " ")]
    (list 'do
          (list 'vim.cmd definition)
          (when (not dirty?)
            (list 'vim.cmd "autocmd!"))
          (when (> (length [...]) 0)
            (list 'do ...))
          (list 'vim.cmd "augroup END"))))

(fn def-augroup [name ...]
  (_create-augroup false name ...))

(fn def-augroup-dirty [name ...]
  (_create-augroup true name ...))

; FIXME definitely refactor
; TODO note to self: don't worry about splicing actual values of autocmd-sym as strings
; you'll have to rip that out when the new api comes anyway
(fn def-autocmd [events patterns rhs]
  (let [events (scall :concat events ",")
        patterns (scall :concat patterns ",")
        f (_zf rhs)
        id '(lime.id)
        autocmd-sym (gensym "zest_autocmd")
        id-sym (gensym "zest_id")
        vlua-sym (gensym "zest_vlua")]

    ; TODO split into two like before, this as the entry point
    (let [cmd-xs (fennel.sequence "autocmd" events patterns (if f vlua-sym rhs))]
      (if (lit? cmd-xs)
        (list 'vim.cmd (scall :concat cmd-xs " "))
        (list 'do
              (if f (list 'local id-sym id))
              (if f (list 'local vlua-sym (list '.. ":call v:lua.zest.autocmd." id-sym ".f()")))
              (list 'local autocmd-sym
                    {: f
                     : events
                     : patterns
                     :rhs (if f vlua-sym rhs)})
              (if f (list 'tset '_G.zest.keymap id-sym autocmd-sym))
              (list 'vim.cmd
                    (list '.. "autocmd "
                        (sym (.. (tostring autocmd-sym) ".events"))
                        " "
                        (sym (.. (tostring autocmd-sym) ".patterns"))
                        " "
                        (sym (.. (tostring autocmd-sym) ".rhs")))))))))

{
 : def-keymap-string
 : def-keymap-fn
 : test
 : def-keymap
 : def-keymap-pairs
 : def-augroup
 : def-augroup-dirty
 : def-autocmd
 }

