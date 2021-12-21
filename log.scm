; Log message to error port and exit
; When developing, it is useful to start `ry` redirecting ("2> messages.log")
; errors to a file that you can then run `tail -f messages.log` on while the
; editor keeps running.
(define (log-err-abort msg)
  (when (get-environment-variable "DEBUG")
    (display (string-append "Error: " msg) (current-error-port))
    (newline (current-error-port))
    (exit 1)))

(define (log-err msg)
  (when (get-environment-variable "DEBUG")
    (display msg (current-error-port))
    (newline (current-error-port))
    msg))

(define (debug-pp sexpr)
  (when (get-environment-variable "DEBUG")
    (format (current-error-port) "~Y" sexpr)))
