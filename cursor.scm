(define (pos-nudge-xy pos x-change y-change)
  (cons
    (+ (car pos) x-change)
    (+ (cdr pos) y-change)))

(define (pos-nudge-x pos x-change)
  (pos-nudge-xy pos x-change 0))

(define (pos-nudge-y pos y-change)
  (pos-nudge-xy pos 0 y-change))

(define (try-move buffer new-pointer)
  (let* ([x (car new-pointer)]
         [y (cdr new-pointer)]
         [lines (buffer-lines buffer)]
         [height (+ (lines-height lines) (if (eq? (current-mode-name) 'insert) 1 0))]
         [ny (cond [(> y height) height]
                   [(< y 0) 0]
                   [else y])]
         [true-width (lines-width lines ny)]
         [width (+ true-width (if (eq? (current-mode-name) 'insert) 1 0))]
         [nx (cond [(> x width) (max 0 width)]
                   [(< x 0) 0]
                   [else x])])
    (cons nx ny)))

(define (ensure-valid-pointer)
  (update-current-buffer-pointer (lambda (buffer)
    (buffer-pointer buffer))))

(define (previous-line)
  (update-current-buffer-pointer (lambda (buffer)
    (pos-nudge-y (buffer-pointer buffer) -1))))

(define (next-line)
  (update-current-buffer-pointer (lambda (buffer)
    (pos-nudge-y (buffer-pointer buffer) 1))))

(define (previous-line-jump)
  (update-current-buffer-pointer (lambda (buffer)
    (pos-nudge-y (buffer-pointer buffer) -15))))

(define (next-line-jump)
  (update-current-buffer-pointer (lambda (buffer)
    (pos-nudge-y (buffer-pointer buffer) 15))))

(define (backward-char)
  (update-current-buffer-pointer (lambda (buffer)
    (pos-nudge-x (buffer-pointer buffer) -1))))

(define (forward-char)
  (update-current-buffer-pointer (lambda (buffer)
    (pos-nudge-x (buffer-pointer buffer) 1))))

(define (backward-char-or-line)
  (if (<= (car (buffer-pointer (current-buffer))) 0)
    (begin (previous-line) (end-of-line))
    (backward-char)))

(define (forward-char-or-line)
  (let* ((l&p (current-buffer-lines-and-pointer))
         (pos (cdr l&p))
         (lines (car l&p)))
    (if (>= (car pos) (lines-width lines (cdr pos)))
      (begin (next-line) (beginning-of-line))
      (forward-char))))

(define (beginning-of-line)
  (update-current-buffer-pointer (lambda (buffer)
    (cons 0 (cdr (buffer-pointer buffer))))))

(define (end-of-line)
  (update-current-buffer-pointer (lambda (buffer)
    (pos-nudge-x (buffer-pointer buffer) 10000))))

(define (beginning-of-buffer)
  (update-current-buffer-pointer (lambda (buffer)
    (cons 0 0))))

(define (end-of-buffer)
  (update-current-buffer-pointer (lambda (buffer)
    (cons 0 (length (buffer-lines buffer))))))

(define (first-non-whitespace)
  (beginning-of-line)
  (next-beginning-of-word))

(define (forward-while-char-match% fn)
  (let loop ((char (current-buffer-char)))
    (if (fn char)
      (let* ((lines-and-pointer (current-buffer-lines-and-pointer))
             (pos (cdr lines-and-pointer))
             (lines (car lines-and-pointer)))
        (cond ((>= (car pos) (lines-width lines (cdr pos))) ; if it's eol
                 (next-line)
                 (beginning-of-line))
              (else
                (forward-char)
                (loop (current-buffer-char))))))))

(define (backward-while-char-match% fn)
  (let loop ((char (current-buffer-char)))
    (if (fn char)
      (let* ((pos (cdr (current-buffer-lines-and-pointer))))
        (cond ((eq? (car pos) 0) ; if it's bol
                 (previous-line)
                 (end-of-line))
               (else
                 (backward-char)
                 (loop (current-buffer-char))))))))

(define (next-beginning-of-word)
  (forward-while-char-match% (lambda (x) (not (char-whitespace? x))))
  (forward-while-char-match% char-whitespace?))

(define (previous-beginning-of-word)
  (backward-char-or-line)
  (backward-while-char-match% char-whitespace?)
  (backward-while-char-match% (lambda (x) (not (char-whitespace? x))))
  (forward-char-or-line))
