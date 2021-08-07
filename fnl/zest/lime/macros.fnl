; NOTE:
; this is not for you
; this is for me

; TODO
; buflocal maps?
; script directory?
; check if partials work as they should

(local fennel (require :zest.fennel))
(local list fennel.list)

;; utils

(local fs {})

(fn fs.exists? [path]
  (os.rename path path))

(fn fs.write [path content]
  (with-open [file (assert (io.open path "w"))]
    (file:write content)))

(fn fs.read [path]
  (with-open [file (assert (io.open path "r"))]
    (file:read "*a")))

(fn fs.lines [path]
  (let [out []]
    (each [l (io.lines path)]
      (table.insert out l))
    out))

(fn uid []
  (local tmp (.. (os.getenv "HOME") "/.zest"))
  (if (not (fs.exists? tmp))
    (fs.write tmp (.. (os.time) "\n" 1)))
  (let [lines (fs.lines tmp)
        time (tonumber (. lines 1))
        id (. lines 2)]
    (if (= (os.time) time)
      (let [id (+ (tonumber id) 1)]
        (fs.write tmp (.. time "\n" id))
        (.. "_" id "_" time))
      (let [id 1
            time (os.time)]
        (fs.write tmp (.. time "\n" id))
        (.. "_" id "_" time)))))

; {{{
;(fn _smart-concat [xs d]
;  "concatenate literals in xs"
;  (let [out []]
;    (var last-string? false)
;    (each [_ v (ipairs xs)]
;      (let [string? (or (= (type v) :string)
;                        (= (type v) :number))
;            len (length out)]
;        (if (and last-string?
;                 string?)
;          (tset out len (.. (. out len) d v))
;          (table.insert out v))
;        (set last-string? string?)))
;    out))
;
;(fn _concat [xs d]
;  (let [d (or d "")]
;    (var out [])
;    (match xs
;      (where s (or (= (type s) :string)
;                   (= (type s) :number)))
;      (table.insert out (tostring s))
;      (where q (fennel.sym? q))
;      (table.insert out `(if (= (type ,xs) :string)
;                           ,xs
;                           (table.concat ,xs ,d)))
;      _ (set out (_smart-concat xs d)))
;    (if (= (length out) 1)
;      `,(unpack out)
;      (if (= d "")
;        `(.. ,(unpack out))
;        `(table.concat ,out ,d)))))
; }}}

;; zest

(fn hasfn? [x] (= (?. x 1 1) :hashfn))
(fn fn? [x] (= (?. x 1 1) :fn))
(fn partial? [x] (= (?. x 1 1) :partial))
(fn capitalised? [s] (string.match (s:sub 1 1) "%u"))

(fn zf [f]
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

;; vlua

(fn _vlua [s f]
  "store a function in _G._zest and return its v:lua, formatting if needed"
  (let [f (zf f)]
    (when f
      (let [id (uid)
            vlua (.. "v:lua._zest." id)]
        (list 'do
              (list 'tset '_G._zest id f)
              (if s
                (list 'string.format s vlua)
                vlua))))))

(fn vlua [x y]
  "prepare arguments for _vlua"
  (match [x y]
    [x nil] (_vlua nil x)
    [x y]   (_vlua x   y)))

;; options

; set-option

(fn _set-option [scope action key val]
  "complete vim.opt wrapper"
  (let [opt (.. "vim.opt" scope "." key)]
    (if action
      (list (sym (.. opt ":" action)) val)
      (list 'set (sym opt) val))))

(fn set-option [x y z]
  "prepare arguments for _set-option"
  (match [x y z]
    [x y nil] (_set-option "" nil (tostring x) (or y true))
    [x y z]   (let [(scope action) (match (tostring (. x 1))
                                     :l (values "_local"  (. x 2))
                                     :g (values "_global" (. x 2))
                                     _  (values ""        (. x 1)))]
                (_set-option scope action (tostring y) (or z true)))))

; get-option? vim.bo/vim.wo vim.o vim.go?

;; keymaps

(fn _keymap-options [args]
  "convert seq of options 'args' to 'modes' string and keymap 'opts'"
  (let [modes (tostring (table.remove args 1))
        opts-xs args
        opts {:noremap true}]
    (each [_ o (ipairs opts-xs)]
      (if (= o :remap)
        (tset opts :noremap false)
        (tset opts o true)))
    (values modes opts)))

; buffer scoped with :buffer0 :buffer1 passed as options. why in a macro though?
(fn def-keymap [args lhs rhs]
  (let [(modes opts) (_keymap-options args)
        id (uid)
        f (zf rhs)
        vlua (if opts.expr
               (.. "v:lua._zest." id ".f()")
               (.. ":call v:lua._zest." id ".f()<cr>"))]
    (list 'do
          (list 'local 'zest_keymap#
                {: f : modes : opts : lhs
                 :rhs (if f vlua rhs)})
          (list 'tset '_G._zest id 'zest_keymap#)
          (let [out []]
            (each [m (modes:gmatch ".")]
              (table.insert out `(vim.api.nvim_set_keymap ,m
                                                          zest_keymap#.lhs
                                                          zest_keymap#.rhs
                                                          zest_keymap#.opts)))
            (unpack out)))))

;; autocmds

; def-augroup

(fn _create-augroup [dirty? name ...]
  "define a new augroup, with or without autocmd!"
  (let [begin (_concat ["augroup" name] " ")]
    (list 'do
          `(vim.cmd ,begin)
          (when (not dirty?)
            `(vim.cmd "autocmd!"))
          (if (> (length [...]) 0)
            (list 'do ...)
            ...)
          `(vim.cmd "augroup END"))))

(fn def-augroup [name ...]
  (_create-augroup false name ...))

(fn def-augroup-dirty [name ...]
  (_create-augroup true name ...))

; def-autocmd

(fn def-autocmd [events patterns rhs]
  (let [events (_concat events ",")
        patterns (_concat patterns ",")
        id (uid)
        f (zf rhs)
        vlua (.. ":call v:lua._zest." id ".f()")]
    (list 'do
          (list 'local 'zest_autocmd#
                {: f : events : patterns
                 :cmd (if f vlua rhs)})
          (list 'tset '_G._zest id 'zest_autocmd#)
          `(vim.cmd (.. "autocmd "
                        zest_autocmd#.events " "
                        zest_autocmd#.patterns " "
                        zest_autocmd#.cmd)))))

{: vlua
 : vlua-format
 : set-option
 : def-keymap
 : def-augroup
 : def-augroup-dirty
 : def-autocmd}
