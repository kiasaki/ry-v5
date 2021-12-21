(define *modes* '())
(define *current-mode* '())

(define (enter-mode new-mode)
  (trigger 'mode-exit (current-mode-name))
  (set! *current-mode* new-mode)
  (trigger 'mode-enter new-mode))

(define (new-mode name keybinding)
  (set! *modes* (cons
                  (cons name keybinding)
                  *modes*))
  (if (null? *current-mode*)
    (set! *current-mode* name))
  (lambda ()
    (enter-mode name)))

(define (current-mode)
  (assq *current-mode* *modes*))

(define (current-mode-name)
  *current-mode*)

(define (current-mode-keybinding)
  (cdr (current-mode)))

(define (mode-match-keypress keybinding key-pressed)
  (let loop ([keys keybinding])
    (cond [(null? keys) #f]
          [else (if (key-eq? key-pressed (caar keys))
                  (cdar keys)
                  (loop (cdr keys)))])))

(define (key-eq? key-a key-b)
  (and (eq? (cdr (assq 'meta? key-a)) (cdr (assq 'meta? key-b)))
       (eq? (cdr (assq 'ctrl? key-a)) (cdr (assq 'ctrl? key-b)))
       (eq? (cdr (assq 'char key-a)) (cdr (assq 'char key-b)))))

(define (make-key% meta? ctrl? ch)
  (list (cons 'meta? meta?)
        (cons 'ctrl? ctrl?)
        (cons 'char ch)))

(define (make-key def)
  (cond [(equal? def "enter") (make-key% #f #f #\x0D)]
        [(equal? def "tab") (make-key% #f #f #\tab)]
        [(equal? def "backspace") (make-key% #f #f #\backspace)]
        [(equal? def "delete") (make-key% #f #f #\delete)]
        [(equal? def "escape") (make-key% #f #f #\escape)]
        [else
          (let* ([start (if (>= (string-length def) 3) (substring def 0 2) "")]
                 [long-start (if (>= (string-length def) 5) (substring def 0 4) "")]
                 [double-key (equal? long-start "M-C-")]
                 [key (or (equal? start "M-") (equal? start "C-"))]
                 [start-index (cond [double-key 4][key 2][else 0])])
            (make-key% (or (equal? start "M-") double-key)
                      (or (equal? start "C-") double-key)
                      (string-ref def start-index)))]))

(define (define-binding alist)
  (alist-map (lambda (key values) (cons (make-key key) values)) alist))

(define (numbers-binding fn)
  (list (cons "0" fn)
    (cons "1" fn) (cons "2" fn) (cons "3" fn)
    (cons "4" fn) (cons "5" fn) (cons "6" fn)
    (cons "7" fn) (cons "8" fn) (cons "9" fn)))

(define (nested-numbers-binding fn)
  (define-binding
    (append
      (numbers-binding fn)
      (numbers-binding
        (define-binding
          (append
            (numbers-binding fn)
            (numbers-binding
              (define-binding
                (numbers-binding fn)))))))))

(define (self-inserting-char-list fn)
  (let loop ([current-char 32]
             [keybindings '()])
    (if (> current-char 126)
      keybindings
      (let ([ch (integer->char current-char)])
        (loop (+ current-char 1) (cons (cons (string ch) (fn ch)) keybindings))))))

(define normal-mode
  (new-mode
    'normal
    (define-binding
      (list
        (cons "q" save-buffers-kill-ry)
        (cons "i" (lambda () (enter-mode 'insert)))
        (cons "a" (lambda () (enter-mode 'insert) (forward-char)))
        (cons "A" (lambda () (enter-mode 'insert) (end-of-line)))
        (cons "I" (lambda () (enter-mode 'insert) (first-non-whitespace)))
        (cons "0" beginning-of-line)
        (cons "$" end-of-line)
        (cons "^" first-non-whitespace)
        (cons "w" next-beginning-of-word)
        (cons "W" next-beginning-of-word)
        (cons "b" previous-beginning-of-word)
        (cons "B" previous-beginning-of-word)
        (cons "o" (lambda () (enter-mode 'insert) (insert-line-down)))
        (cons "O" (lambda () (enter-mode 'insert) (insert-line-up)))
        (cons "h" backward-char)
        (cons "j" next-line)
        (cons "k" previous-line)
        (cons "l" forward-char)
        (cons "g" (define-binding (list
          (cons "g" beginning-of-buffer))))
        (cons "G" end-of-buffer)
        (cons "C-d" next-line-jump)
        (cons "C-u" previous-line-jump)
        (cons "y" (define-binding (list
          (cons "y" copy-line))))
        (cons "p" paste)
        (cons "C-x" (define-binding (list
          (cons "C-s" save-file)
          (cons "C-f" open-file)
          (cons "C-c" kill-ry))))
        (cons "C-w" (define-binding (list
          (cons "q" quit-window)
          (cons "h" window-move-left)
          (cons "j" window-move-down)
          (cons "k" window-move-up)
          (cons "l" window-move-right)
          (cons "s" split-window-horizontally)
          (cons "C-s" split-window-horizontally)
          (cons "v" split-window-vertically)
          (cons "C-v" split-window-vertically))))
        (cons "d" (define-binding (list
          (cons "d" kill-whole-line)
          (cons "h" delete-backward-char)
          (cons "j" delete-backward-char)
          (cons "k" delete-forward-char)
          (cons "l" delete-forward-char))))
        (cons ":" smex)
        (cons "x" delete-char-under-cursor)
        (cons "r" (define-binding (self-inserting-char-list change-char)))))))

(define insert-mode
  (new-mode
    'insert
    (define-binding
      (append
        (self-inserting-char-list self-insert-char)
        (list
          (cons "enter" newline-at-pointer)
          (cons "tab" insert-tab)
          (cons "escape" (lambda () (enter-mode 'normal) (backward-char)))
          (cons "backspace" delete-backward-char)
          (cons "delete" delete-backward-char))))))

(define command-mode
  (new-mode
    'command
    (define-binding
      (append
        (self-inserting-char-list command-mode-insert-char)
        (list
          (cons "enter" command-mode-commit)
          (cons "escape" exit-command-mode)
          (cons "backspace" command-mode-delete-char)
          (cons "delete" command-mode-delete-char))))))
