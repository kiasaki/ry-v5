(import chicken scheme)
(use termbox format alist-lib posix utils s)
(require-extension utf8)
(require-extension utf8-srfi-13)
(require-extension utf8-srfi-14)
(require-extension regex)

(define *running* #t)

(define (set-running-state state)
  (set! *running* state))

(include "log.scm")
(include "util.scm")
(include "term.scm")
(include "events.scm")
(include "yanking.scm")

(include "minibuffer.scm")
(include "buffer.scm")
(include "windows.scm")

(include "display.scm")
(include "cursor.scm")
(include "commands.scm")

(include "modes.scm")

; Take in the top level keybinding for current mode at first
; Then, if matching in a sub keybinding, poll for an other keypress
; until (mode-match-keypress) gives back a proc or nothing.
(define (poll-input keybinding)
  (term-poll (lambda (mod key ch)
    (define ctrl? #f)
    (define char (integer->char ch))

    (cond [(eq? key key-esc)        (set! char #\escape)]
          [(eq? key key-tab)        (set! char #\tab)]
          [(eq? key key-enter)      (set! char #\x0D)]
          [(eq? key key-space)      (set! char #\space)]
          [(eq? key key-backspace)  (set! char #\backspace)]
          [(eq? key key-backspace2) (set! char #\delete)]
          [(eq? key key-delete)     (set! char #\delete)]
          [(eq? key key-ctrl-a)     (set! char #\a) (set! ctrl? #t)]
          [(eq? key key-ctrl-b)     (set! char #\b) (set! ctrl? #t)]
          [(eq? key key-ctrl-c)     (set! char #\c) (set! ctrl? #t)]
          [(eq? key key-ctrl-d)     (set! char #\d) (set! ctrl? #t)]
          [(eq? key key-ctrl-e)     (set! char #\e) (set! ctrl? #t)]
          [(eq? key key-ctrl-f)     (set! char #\f) (set! ctrl? #t)]
          [(eq? key key-ctrl-g)     (set! char #\g) (set! ctrl? #t)]
          [(eq? key key-ctrl-h)     (set! char #\h) (set! ctrl? #t)]
          [(eq? key key-ctrl-i)     (set! char #\i) (set! ctrl? #t)]
          [(eq? key key-ctrl-j)     (set! char #\j) (set! ctrl? #t)]
          [(eq? key key-ctrl-k)     (set! char #\k) (set! ctrl? #t)]
          [(eq? key key-ctrl-l)     (set! char #\l) (set! ctrl? #t)]
          [(eq? key key-ctrl-m)     (set! char #\m) (set! ctrl? #t)]
          [(eq? key key-ctrl-n)     (set! char #\n) (set! ctrl? #t)]
          [(eq? key key-ctrl-o)     (set! char #\o) (set! ctrl? #t)]
          [(eq? key key-ctrl-p)     (set! char #\p) (set! ctrl? #t)]
          [(eq? key key-ctrl-q)     (set! char #\q) (set! ctrl? #t)]
          [(eq? key key-ctrl-r)     (set! char #\r) (set! ctrl? #t)]
          [(eq? key key-ctrl-s)     (set! char #\s) (set! ctrl? #t)]
          [(eq? key key-ctrl-t)     (set! char #\t) (set! ctrl? #t)]
          [(eq? key key-ctrl-u)     (set! char #\u) (set! ctrl? #t)]
          [(eq? key key-ctrl-v)     (set! char #\v) (set! ctrl? #t)]
          [(eq? key key-ctrl-w)     (set! char #\w) (set! ctrl? #t)]
          [(eq? key key-ctrl-x)     (set! char #\x) (set! ctrl? #t)]
          [(eq? key key-ctrl-y)     (set! char #\y) (set! ctrl? #t)]
          [(eq? key key-ctrl-z)     (set! char #\z) (set! ctrl? #t)])

    (if (eq? key key-ctrl-c)
      (kill-ry))

    (let* ([key-pressed (make-key% (eq? mod mod-alt) ctrl? char)]
           [current-key-handler (mode-match-keypress keybinding key-pressed)])
      (debug-pp (list key-pressed (if (procedure? current-key-handler) current-key-handler 'keymap)))
      (cond [(procedure? current-key-handler) (current-key-handler)]
            [(list? current-key-handler) (poll-input current-key-handler)])))))

; Main application loop, at this point our code is wrapped in exception
; handling.
; All we need to do is set up the editor:
;  - Load file if one was passed as CLI arg
;  - Ensure we have a buffer (empty or from file)
;  - Initialize window tree with newly created buffer
;  - Enter normal mode
;  - Welcome user
; After that we loop alternating between rendering and polling for keys
(define (main-loop)
  ; setup
  (let ([buffer-n (if (null? (command-line-arguments))
          (add-buffer (new-buffer))
          (add-buffer (new-buffer-from-file (car (command-line-arguments)))))])
    (init-window-tree buffer-n)
    (enter-mode 'normal)
    (set-minibuffer-message "Thanks for using ry!"))

  ; loop
  (let loop ()
    (term-update)
    (display-windows)
    (display-minibuffer)
    (term-flush)
    (poll-input (current-mode-keybinding))
    (when *running* (loop))))

(define (handle-exception exn)
  (term-shutdown)
  (print-error-message exn)
  (newline)
  (print-call-chain)
  (exit 1))

(define (main)
  (handle-exceptions exn (handle-exception exn)
    (begin
      (term-init)
      (main-loop)
      (term-shutdown))))

(main)
