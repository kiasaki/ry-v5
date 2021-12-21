(define (kill-ry)
  (set-running-state #f))

; TODO Actually save
(define (save-buffers-kill-ry)
  (kill-ry))

; Callback getting command entered.
; Evals given text and pretty prints result to minibuffer
(define (smex-commit command-text)
  (if command-text
    (let* ([corrected-command-text ; automatically appen ) to commands if needed
              (if (eq? #\) (string-ref command-text (- (string-length command-text) 1)))
                (string-append "(" command-text)
                (string-append "(" command-text ")"))]
            [eval-result (eval-string corrected-command-text)])
      (if (car eval-result)
        (when (cdr eval-result)
          (set-minibuffer-message (cdr eval-result)))
        (set-minibuffer-error (cdr eval-result))))))

; `smex` reading input from the minibuffer and evals it
; It's similar to ":" in vim or M-x in emacs
(define (smex)
  (edit-minibuffer "(" smex-commit))

(define *text-save-file* "Save file to: ")
(define *text-open-file* "Open file: ")

; Save current file to disk
(define (save-file)
  (let* ([buffer (current-buffer)]
         [lines (buffer-lines buffer)])
    (if (buffer-location buffer)
      ; save file
      (begin
        (buffer-save buffer)
        (set-minibuffer-message (string-append
          "Written: \"" (buffer-name buffer) "\" "
          (number->string (length lines)) "L, "
          (number->string (string-length (string-join lines "\n"))) "C")))
      ; ask for filename & then save
      (edit-minibuffer *text-save-file* (lambda (filename)
        (update-current-buffer-prop 'location (lambda (buffer)
          (if (absolute-pathname? filename)
            filename
            (make-pathname (current-directory) filename)))))
      (save-file))))
  #f)

(define (open-file)
  (edit-minibuffer *text-open-file* (lambda (filename)
    (let* ([buffer (new-buffer-from-file filename)]
           [buffer-n (add-buffer buffer)])
      (update-current-window-prop 'buffer (lambda (w) buffer-n)))))
  #f)

; Splits a list in two at a define `elt` index
(define (split-elt l elt)
  (let loop ((head '())
             (tail l)
             (i 0))
   (if (eq? tail '())
     (values l '())
     (if (= elt i)
       (values (reverse head) tail)
       (loop (cons (car tail) head)
             (cdr tail)
             (+ i 1))))))

(define (split-elt-cell l elt)
  (call-with-values
    (lambda () (split-elt l elt))
    (lambda (lhead lrest) (cons lhead lrest))))

(define (insert-string% lines pos str)
  (let* ((split-result (split-elt-cell lines (cdr pos)))
         (head (car split-result))
         (rest (cdr split-result))
         (lsplit-result (split-elt-cell (string->list (car (or rest '("")))) (car pos)))
         (lhead (car lsplit-result))
         (lrest (cdr lsplit-result)))
    (append head (cons (list->string (append lhead (string->list str) lrest)) (or (cdr rest) '(""))))))

(define (insert-char% lines pos new-char)
  (insert-string% lines pos (string new-char)))

(define (delete-char% lines pos)
  (if (and (>= (cdr pos) 0)
           (< (cdr pos) (length lines))
           (< (car pos) (string-length (list-ref lines (cdr pos))))
           (>= (car pos) 0))
    (let* ((split-result (split-elt-cell lines (cdr pos)))
           (head (car split-result))
           (rest (cdr split-result))
           (line (car (or rest '("")))))
      (append head (cons
                     (if (eq? 0 (string-length line))
                       line
                       (string-append
                         (substring line 0 (car pos))
                         (substring line (+ 1 (car pos)) (string-length line))))
                     (cdr rest))))
    lines))

(define (change-char% lines pos new-char)
  (insert-char% (delete-char% lines pos) pos new-char))

(define (delete-line% lines line)
  (if (< line (length lines))
    (call-with-values
      (lambda () (split-elt lines line))
      (lambda (head rest) (append head (cdr rest))))
    lines))

; Deletes a x1 to x2 part of a line
; returns (cons string-removed new-lines)
(define (delete-line-part% lines y x1 x2)
  (if (and (< y (length lines)) (>= y 0))
    (if (and (< x1 (string-length (list-ref lines y))) (>= x1 0))
      (let* ([splitted-lines (split-elt-cell lines y)]
             [splitted-line (split-elt-cell (string->list (car (cdr splitted-lines))) x1)]
             [end-splitted-line (split-elt-cell (cdr splitted-line) (- x2 x1))])
        (cons
          (list->string (car end-splitted-line))
          (append
            (car splitted-lines)
            (list (list->string (append (car splitted-line) (cdr end-splitted-line))))
            (cdr (cdr splitted-lines)))))
      (cons "" lines))
    (cons "" lines)))

(define (whitespace-at-bol-length% line)
  (-
    (string-length line)
    (string-length (string-trim line))))

(define (insert-line% lines line)
  (if (< line (length lines))
    (call-with-values
      (lambda () (split-elt lines line))
      (lambda (head rest)
        (let* ([current-line (or (car (reverse
                                        (if (eq? head '())
                                          '("") head)))
                                 "")]
               [whitespace-length (whitespace-at-bol-length% current-line)]
               [new-line (make-string whitespace-length #\space)])
          (append head (list new-line) rest))))
    lines))

(define (self-insert-char ch)
  (lambda ()
    (update-current-buffer-prop 'lines (lambda (buffer)
      (insert-char% (buffer-lines buffer) (buffer-pointer buffer) ch)))
    (forward-char)))

(define (change-char ch)
  (lambda ()
    (update-current-buffer-prop 'lines (lambda (buffer)
      (change-char% (buffer-lines buffer) (buffer-pointer buffer) ch)))))

(define (kill-whole-line)
  (update-current-buffer-prop 'lines (lambda (buffer)
    (delete-line% (buffer-lines buffer) (cdr (buffer-pointer buffer)))))
  (ensure-valid-pointer))

(define (delete-char)
  (update-current-buffer-prop 'lines (lambda (buffer)
    (delete-char% (buffer-lines buffer) (buffer-pointer buffer))))
  (ensure-valid-pointer))

(define (delete-backward-char)
  (if (eq? (car (buffer-pointer (current-buffer))) 0)
    (begin
      (previous-line)
      (end-of-line)
      (update-current-buffer-prop 'lines (lambda (buffer)
        (let ([lines (buffer-lines buffer)]
              [pointer (buffer-pointer buffer)])
          (insert-string% lines pointer (list-ref lines (+ (cdr pointer) 1))))))
      (update-current-buffer-prop 'lines (lambda (buffer)
        (delete-line% (buffer-lines buffer) (+ (cdr (buffer-pointer buffer)) 1)))))
    (begin
      (backward-char)
      (delete-char))))

(define delete-forward-char delete-char)

(define (delete-char-under-cursor)
  (let* ([buffer (current-buffer)]
         [pointer (buffer-pointer buffer)]
         [lines (buffer-lines buffer)])
  (if (eq? (car pointer) (string-length (list-ref lines (cdr pointer))))
    (begin
      (backward-char)
      (delete-char))
    (delete-forward-char))))

(define (insert-line-up)
  (update-current-buffer-prop 'lines (lambda (buffer)
    (insert-line% (buffer-lines buffer) (cdr (buffer-pointer buffer)))))
  (end-of-line))

(define (insert-line-down)
  (next-line)
  (update-current-buffer-prop 'lines (lambda (buffer)
    (let ([p (cdr (buffer-pointer buffer))])
      (if (= p (length (buffer-lines buffer)))
        (append (buffer-lines buffer) '("")) ; just append a new line if we're at the end of the file
        (insert-line% (buffer-lines buffer) p)))))
  (end-of-line))

(define (newline-at-pointer)
  (update-current-buffer-prop 'lines (lambda (buffer)
    (let* ([pointer (buffer-pointer buffer)]
           [lines (buffer-lines buffer)]
           [current-line (if (< (cdr pointer) (length lines)) (list-ref lines (cdr pointer)) "")]
           [current-line-length (max (string-length current-line) 0)]
           [new-line-part-and-lines (delete-line-part% lines
             (cdr pointer) (car pointer) current-line-length)]
           [next-line-y (+ (cdr pointer) 1)]
           [lines-with-blank-line (insert-line%
             (cdr new-line-part-and-lines) next-line-y)]
           [lines-with-text-on-new-line (insert-string%
             lines-with-blank-line (cons 0 next-line-y) (car new-line-part-and-lines))])
      lines-with-text-on-new-line)))
  (next-line)
  (first-non-whitespace))

(define (insert-tab)
  ((self-insert-char #\space))
  ((self-insert-char #\space)))

;;; Shortcuts
(define q kill-ry)
(define quit kill-ry)
(define w save-file)
(define e open-file)
