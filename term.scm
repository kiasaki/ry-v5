;;; termbox wrapper layer
;;;
;;; This abstraction layer is user to give us the flexibility for change the
;;; backing terminal drawing library, ncurses and it's quirks and is pretty
;;; heavy for our use case but works out of the box on many systems.

(define term-c-default 0);(hex->term #x232C31))
(define term-c-black 0);(hex->term #x232C31))
(define term-c-black-light 8);(hex->term #x3F4944))
(define term-c-red 1);(hex->term #x2A5491))
(define term-c-red-light 9);(hex->term #x2A5491))
(define term-c-green 2);(hex->term #x237986))
(define term-c-green-light 10);(hex->term #x237986))
(define term-c-yellow 3);(hex->term #xA03B1E))
(define term-c-yellow-light 11);(hex->term #xA03B1E))
(define term-c-blue 4);(hex->term #x484D79))
(define term-c-blue-light 12);(hex->term #x484D79))
(define term-c-magenta 5);(hex->term #xC59820))
(define term-c-magenta-light 13);(hex->term #xC59820))
(define term-c-cyan 6);(hex->term #xB02F30))
(define term-c-cyan-light 14);(hex->term #xB02F30))
(define term-c-white 7);(hex->term #x9EA7A6))
(define term-c-white-light 15);(hex->term #xb5d8f6))
(define term-c-gray 240)

(define term-a-bold bold)
(define term-a-underline underline)
(define term-a-reversed reversed)

(define term-height 0)
(define term-width 0)

(define (term-init)
  (init)
  ;(input-mode 'esc)
  (output-mode 256))

(define (term-shutdown)
  (shutdown))

(define (term-update)
  (set! term-width (width))
  (set! term-height (height))
  (clear)
  (let loop ([cell (create-cell #\space (style term-c-default) (style term-c-default))]
             [i 0])
    (if (< i (* term-width term-height))
      (begin
        (put-cell! (inexact->exact (floor (/ i term-width))) (modulo i term-width) cell)
        (loop cell (+ i 1))))))

(define (term-flush)
  (present))

(define (term-move x y)
  (cursor-set! x y))

(define (splice alist blist)
  (let f ([a alist] [b blist] [nl '()])
    (if (or (null-list? a) (null-list? b))
      nl
      (f (cdr a) (cdr b)
         (append nl `(,(cons (car a) (car b))))))))

(define (cell-string str fg bg)
  (map (cut create-cell <> fg bg) (string->list str)))

; argument: ("astring" fg bg)
(define (color-strings col-s)
  (apply cell-string col-s))

(define (apply-color mlist collist)
  (apply append
         (map
           color-strings
           (splice mlist collist))))

(define (term-create-cells string fg bg)
  (let ((s (string-match "([^;]*)(.*)" string)))
    (if s
      (apply-color (cdr s) `((,fg ,bg) (,term-c-gray ,bg)))
      (cell-string string fg bg))))

(define (term-display x y text #!optional
                      (fg term-c-black) (bg term-c-default) (attr #f))
  (let* ([fg-style (if attr (style fg attr) (style fg))]
         [bg-style (style bg)]
         [cells (term-create-cells text fg-style bg-style)])
    (let loop ([i 0][cells-left cells])
      (when (not (or (null? cells-left) (null-list? cells-left)))
        (put-cell! (+ x i) y (car cells-left))
        (loop (+ i 1) (cdr cells-left))))))

(define (term-display-with base-x base-y fg bg attr fn)
  (fn (lambda (x y text)
    (let ([rx (+ base-x x)]
          [ry (+ base-y y)])
      (term-display rx ry text fg bg attr)))))

(define (term-poll fn)
  (poll fn (lambda (x y) (term-poll fn))))
