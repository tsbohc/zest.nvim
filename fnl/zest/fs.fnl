(local fs {})

(fn fs.read [path]
  (with-open [file (assert (io.open path "r"))]
    (file:read "*a")))

(fn fs.write [path content]
  (with-open [file (assert (io.open path "w"))]
    (file:write content)))

(fn fs.dirname [path]
  (path:match "(.*[/\\])"))

(fn fs.mkdir [path]
  (os.execute (.. "mkdir -p " path)))

(fn fs.isdir [path]
  (let [file (io.open path "r")]
    (if (= nil file)
      false
      (do
        (file:close)
        true))))

fs
