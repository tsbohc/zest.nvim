(local fennel (require :zest.fennel))
(local lime (require :zest.lime.lime)) ; for some reason init.fnl was not being picked up as :zest.lime

(fn hasfn? [x] (= (?. x 1 1) :hashfn))
(fn fn? [x] (= (?. x 1 1) :fn))
(fn partial? [x] (= (?. x 1 1) :partial))
(fn capitalised? [s] (string.match (s:sub 1 1) "%u"))

(fn _zf [f]
  "treat a function before passing it off to vlua"
  (let [f (if (fennel.sequence? f)
            `(fn [] ,(unpack f))
            f)]
    (if (or (fn? f)
              (hasfn? f)
              (partial? f)
              (and (fennel.sym? f)
                   (capitalised? (tostring f))))
      f)))

(fn literal? [x]
  "check if 'x' is safe to evaluate a compile time"
  (if (= x nil)
    true
    (if (or (= (type x) :string)
            (= (type x) :number))
      true
      (if (fennel.sequence? x)
        (do
          (each [_ v (ipairs x)]
            (if (not (literal? v))
              (lua "return false")))
          true)
        false))))

; FIXME only the first argument is checked for safety
(fn scall [f x ...]
  "safely call a lime function in compile or run time"
  (if (literal? x)
    ((. lime f) x ...)
    (list (sym (.. "lime." f)) x ...)))

;; keymaps

; FIXME this is probably over engineered very hard
; i should just consider options literal and stop doing this
; vim doesn't allow passing modes or <expr> does it?
; it makes sense with autocmds, but here? it's too much of a bother
;(fn def-keymap [opts lhs rhs]
;  (let [f (_zf rhs)
;        id-sym (gensym "zest_id")
;        modes-sym (gensym "zest_modes")
;        opts-sym (gensym "zest_opts")
;        vlua-sym (gensym "zest_vlua")
;        keymap-sym (gensym "zest_keymap")
;        id '(lime.id)]
;    (list 'do
;          (list 'local modes-sym (list 'table.remove opts 1))
;          (list 'local opts-sym (scall :keymap-opts opts))
;          (if f (list 'local id-sym '(lime.id)))
;          (if f (list 'local vlua-sym (list 'string.format (scall :format opts :keymap) id-sym)))
;          (list 'local keymap-sym
;                {
;                 :kind :keymap
;                 :modes modes-sym
;                 :opts opts-sym
;                 : lhs
;                 :rhs (if f vlua-sym rhs)
;                 : f
;                 })
;          (if f (list 'tset '_G.zest.keymap id-sym keymap-sym))
;
;          )))

; FIXME i think it'd be better if i just split those into two. extracting some code and repeating a bit is better than this
(fn def-keymap [args lhs rhs]

  ; TODO extract options like you had before
  (let [modes (tostring (table.remove args 1))
        opts (let [opts {:noremap true}]
               (each [_ o (ipairs args)]
                 (if (= o :remap)
                   (tset opts :noremap false)
                   (tset opts o true)))
               opts)

        ; TODO separate into normal and fn macros and use this one as the entry point
        f (_zf rhs)
        id (scall :keymap_id lhs modes)
        id-sym (gensym "zest_id")
        keymap-sym (gensym "zest_keymap")
        opts-sym (gensym "zest_opts")]
    (list 'do
          (if f (list 'local id-sym id))
          (if (and f (not (literal? id))) (list 'local opts-sym opts))
          (list 'local keymap-sym
                {
                 ;: modes
                 : f
                 : lhs
                 :opts (if (and f (not (literal? id))) opts-sym opts)
                 :rhs (if (not f)
                        rhs
                        (if (literal? id)
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

; for now anyway
(fn def-keymap-pairs [args xt]
  (let [modes (tostring (table.remove args 1))
        opts (let [opts {:noremap true}]
               (each [_ o (ipairs args)]
                 (if (= o :remap)
                   (tset opts :noremap false)
                   (tset opts o true)))
               opts)]
    (list 'do
          (list 'local 'zest_opts# opts)
          (let [out []]
            (each [k v (pairs xt)]
              (if (= modes "nvo") ; TODO a better check
                (table.insert out `(vim.api.nvim_set_keymap "" ,k ,v zest_opts#))
                (each [m (modes:gmatch ".")]
                  (table.insert out `(vim.api.nvim_set_keymap ,m ,k ,v zest_opts#)))))
            (unpack out)))))

(fn test []
  (list 'print (tostring (gensym "_G.zest.ya"))))

;(fn def-keymap []
;  (list 'local '(one# two#) (list 'foo)))

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
      (if (literal? cmd-xs)
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

{: test
 : def-keymap
 : def-keymap-pairs
 : def-augroup
 : def-augroup-dirty
 : def-autocmd
 }

