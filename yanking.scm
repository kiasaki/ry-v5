(define *yanking-registers* '(
  (#\. . #f) (#\a . #f) (#\b . #f) (#\c . #f) (#\d . #f)
  (#\e . #f) (#\f . #f) (#\g . #f) (#\h . #f) (#\i . #f)
  (#\j . #f) (#\k . #f) (#\l . #f) (#\m . #f) (#\n . #f)
  (#\o . #f) (#\p . #f) (#\q . #f) (#\r . #f) (#\s . #f)
  (#\t . #f) (#\u . #f) (#\v . #f) (#\w . #f) (#\x . #f)
  (#\y . #f) (#\z . #f)))

(define (copy-line)
  (let* ([buffer (current-buffer)]
         [lines (buffer-lines buffer)]
         [line (or (list-ref lines (cdr (buffer-pointer buffer))) "")])
    (set! *yanking-registers* (set-assq *yanking-registers* #\. (list line)))))

(define (paste)
  (let ([text-to-insert (cdr (assq #\. *yanking-registers*))])
    (if text-to-insert
      (begin
        (update-current-buffer-prop 'lines (lambda (buffer)
          (let* ([y (+ (cdr (buffer-pointer buffer)) 1)]
                [lines (buffer-lines buffer)]
                [head-and-tail (split-elt-cell lines y)])
            (append (car head-and-tail) text-to-insert (cdr head-and-tail)))))
        (next-line))
      (set-minibuffer-error "Nothing in register ."))))
