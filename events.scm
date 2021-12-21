(define *handlers* '())
(define *currently-triggering* #f)

(define (on event-names handler)
  (set! *handlers* (append *handlers*
    (map (lambda (event-name)
      (cons event-name handler)) event-names))))

(define (trigger event-name arg)
  (when (not *currently-triggering*)
    (set! *currently-triggering* #t)
    (let loop ([handlers *handlers*])
      (when (not (null? handlers))
        (when (eq? event-name (caar handlers))
          ((cdar handlers) arg))
        (loop (cdr handlers))))
    (set! *currently-triggering* #f)))

;; Implemented events
;; - buffer-create
;; - buffer-write

(on '(buffer-edit) (lambda (buffer)
  (update-buffer-by-number (buffer-number buffer) (lambda (buffer)
    (set-assq buffer 'modified? #t)))))

(on '(buffer-write) (lambda (buffer)
  (update-buffer-by-number (buffer-number buffer) (lambda (buffer)
    (set-assq buffer 'modified? #f)))))
