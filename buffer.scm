(define *buffers* '())
(define *buffers-index* 0)

(define (new-buffer)
  (list (cons 'number -1)
        (cons 'modified? #f)
        (cons 'readonly? #f)
        (cons 'name "*unnamed*")
        (cons 'location #f)
        (cons 'pointer (cons 0 0))
        (cons 'lines '())))

(define (new-buffer-from-file filename)
  (let* ([full-filename (if (absolute-pathname? filename)
                          filename
                          (make-pathname (current-directory) filename))]
         [file-exists (file-exists? full-filename)]
         [file-lines (if file-exists (string-split (string-trim-right (read-all full-filename) #\newline) "\n" #t) '())])
    (list (cons 'number -1)
          (cons 'modified? #f)
          (cons 'readonly? #f)
          (cons 'name filename)
          (cons 'location full-filename)
          (cons 'pointer (cons 0 0))
          (cons 'lines file-lines))))

(define (kill-buffer-by-number n)
  (set! *buffers* (del-assq n *buffers*)))

(define (get-buffer-by-number n)
  (cdr (assq n *buffers*)))

(define (map-buffers! fn)
  (set! *buffers* (alist-map fn *buffers*)))

(define (add-buffer buffer)
  (set! *buffers-index* (+ *buffers-index* 1))
  (let ([buffer-with-number (set-assq buffer 'number *buffers-index*)])
    (set! *buffers* (cons (cons *buffers-index* buffer-with-number) *buffers*))
    (trigger 'buffer-create buffer-with-number)
    *buffers-index*))

(define (current-buffer-number)
  (cdr (assq 'buffer (current-window))))

(define (current-buffer)
  (window-buffer (current-window)))

(define (current-buffer-lines-and-pointer)
  (let ((buffer (current-buffer)))
    (cons (buffer-lines buffer) (buffer-pointer buffer))))

(define (current-buffer-char)
  (let* ((lines-and-pointer (current-buffer-lines-and-pointer))
         (pos (cdr lines-and-pointer))
         (line (list-ref (car lines-and-pointer) (cdr pos))))
    (if (eq? (string-length line) 0)
      #\newline
      (string-ref line (car pos)))))


(define (buffer-name buffer)
  (cdr (assq 'name buffer)))

(define (buffer-modified? buffer)
  (cdr (assq 'modified? buffer)))

(define (buffer-readonly? buffer)
  (cdr (assq 'readonly? buffer)))

(define (buffer-pointer buffer)
  (cdr (assq 'pointer buffer)))

(define (buffer-location buffer)
  (cdr (assq 'location buffer)))

(define (buffer-lines buffer)
  (cdr (assq 'lines buffer)))

(define (buffer-number buffer)
  (cdr (assq 'number buffer)))

(define (update-buffer-by-number k fn)
  (map-buffers! (lambda (n buffer)
    (cons n (if (eq? n k) (fn buffer) buffer)))))

(define (update-current-buffer-prop prop fn)
  (let ([buffer-n (current-buffer-number)])
    (update-buffer-by-number buffer-n (lambda (buffer)
      (set-assq buffer prop (fn buffer))))
    (when (eq? prop 'lines) ; TODO this shouln't be in ...-current-buffer but someting more generic
      (trigger 'buffer-edit (get-buffer-by-number buffer-n)))))

(define (update-current-buffer-pointer fn)
  (update-current-buffer-prop 'pointer (lambda (buffer)
    (try-move buffer (fn buffer)))))

(define (buffer-save buffer)
  (let* ([flags (+ open/wronly open/creat)]
         [file-descriptor (file-open (buffer-location buffer) flags)])
    (trigger 'buffer-write buffer)
    (file-write file-descriptor (string-join (buffer-lines buffer) "\n" 'suffix))))
