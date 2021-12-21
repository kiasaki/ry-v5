(define minibuffer-error? #f)
(define minibuffer-text "")
(define minibuffer-command-text "")

(define (set-minibuffer-message message)
  (set! minibuffer-error? #f)
  (set! minibuffer-text message)
  (set! minibuffer-command-text ""))

(define (set-minibuffer-error message)
  (set! minibuffer-error? #t)
  (set! minibuffer-text message)
  (set! minibuffer-command-text ""))

(define (set-minibuffer-command command-text)
  (set! minibuffer-error? #f)
  (set! minibuffer-text "")
  (set! minibuffer-command-text command-text))

(define command-mode-handler (make-parameter #f))
(define command-mode-previous-mode (make-parameter #f))

(define (command-mode-insert-char ch)
  (lambda ()
    (set! minibuffer-text (string-append-char minibuffer-text ch))))

(define (command-mode-delete-char)
  (set! minibuffer-text (string-drop-right minibuffer-text 1)))

(define (command-mode-commit)
  (let ([text minibuffer-text]
        [handler (command-mode-handler)]
        [previous-mode (command-mode-previous-mode)])
    (set-minibuffer-message "")
    (command-mode-handler #f)
    (command-mode-previous-mode #f)
    (if previous-mode (enter-mode previous-mode) (enter-mode 'normal))
    (if handler (handler text))))

(define (edit-minibuffer input-text fn)
  (set-minibuffer-command input-text)
  (command-mode-previous-mode (current-mode-name))
  (enter-mode 'command)
  (command-mode-handler fn))

(define (exit-command-mode)
  (let ([previous-mode (command-mode-previous-mode)])
    (set-minibuffer-message "")
    (command-mode-handler #f)
    (command-mode-previous-mode #f)
    (if previous-mode (enter-mode previous-mode) (enter-mode 'normal))))
