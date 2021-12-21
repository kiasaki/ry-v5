;;; ncurses wrapper layer
;;;
;;; This abstraction layer is user to give us the flexibility for change the
;;; backing terminal drawing library, ncurses and it's quirks and is pretty
;;; heavy for our use case but works out of the box on many systems.

(define term-height 0)
(define term-width 0)

(define (term-init)
  (initscr)
  (cbreak)
  (noecho)
  (start_color)
  (keypad (stdscr) #t))

(define (term-shutdown)
  (endwin))

(define (term-update)
  (wclear (stdscr))
  (let-values ([[my mx] (getmaxyx (stdscr))])
    (set! term-width mx)
    (set! term-height my)))

(define (term-flush)
  (wrefresh (stdscr)))

(define (term-move x y)
  (move y x))

(define (term-display x y text)
  (mvaddstr y x text))

(define *color-pair-index* 0)

(define (term-display-with f b a fn)
  (let ([fg (if (eq? f -1) COLOR_WHITE f)]
        [bg (if (eq? b -1) COLOR_BLACK b)]
        [attr (if (eq? a -1) A_NORMAL a)])
    (set! *color-pair-index* (modulo (+ *color-pair-index* 1) 256))
    (init_pair *color-pair-index* fg bg)
    (attron (COLOR_PAIR *color-pair-index*))
    (attron attr)
    (fn)
    (attroff attr)
    (attroff (COLOR_PAIR *color-pair-index*))))

(define (term-display-with-xy-base base-x base-y fn)
  (fn (lambda (x y text)
    (let ([rx (+ base-x x)]
          [ry (+ base-y y)])
      (term-display rx ry text)))))

(define (term-readch)
  (getch))

