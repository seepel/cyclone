(define-library (scheme base)
  ;; In the future, may include this here: (include "../srfi/9.scm")
  (export
    ; TODO: need filter for the next two. also, they really belong in SRFI-1, not here
    ;delete
    ;delete-duplicates
    ;; TODO: possibly relocating here in the future
    ;define-record-type
    ;  register-simple-type
    ;  make-type-predicate
    ;  make-constructor
    ;  make-getter
    ;  make-setter
    ;  slot-set!
    ;  type-slot-offset
    abs
    max
    min
    modulo
    floor-remainder
    even?
    exact-integer?
    exact?
    inexact?
    odd?
    gcd
    lcm
    quotient
    remainder
    truncate-quotient 
    truncate-remainder 
    truncate/ 
    floor-quotient 
    floor-remainder 
    floor/ 
    square
    expt
    call-with-current-continuation
    call/cc
    call-with-values
    dynamic-wind
    values
    char=?
    char<?
    char>?
    char<=?
    char>=?
    string=?
    string<?
    string<=?
    string>?
    string>=?
    foldl
    foldr
    not
    list?
    zero?
    positive?
    negative?
    append
    list
    make-list
    list-copy
    map
    for-each
    list-tail
    list-ref
    list-set!
    reverse
    boolean=?
    symbol=?
    Cyc-obj=?
    vector
    vector-append
    vector-copy
    vector-copy!
    vector-fill!
    vector->list
    vector->string
    vector-map
    vector-for-each
    make-string
    string
    string-copy
    string-copy!
    string-fill!
    string->list
    string->vector
    string-map
    string-for-each
    make-parameter
    current-output-port
    current-input-port
    current-error-port
    call-with-port
    ; TODO: error-object?
    ; TODO: error-object-message
    ; TODO: error-object-irritants
    ; TODO: file-error?
    ; TODO: read-error?
    error
    raise
    raise-continuable
    with-exception-handler
    Cyc-add-exception-handler
    Cyc-remove-exception-handler
    newline
    write-char
    write-string
    flush-output-port
    read-line
    read-string
    input-port?
    output-port?
    input-port-open?
    output-port-open?
    features
    any
    every
    and
    or
    let
    let*
    letrec
    begin
    case
    cond
    cond-expand
    do
    when
    unless
    quasiquote
    floor
    ceiling
    truncate
    round
    exact
    inexact
    eof-object

;;;;
; Possibly missing functions:
;
;    ; byte vectors are not implemented yet:
;    bytevector
;    bytevector-append
;    bytevector-copy
;    bytevector-copy!
;    bytevector-length
;    bytevector-u8-ref
;    bytevector-u8-set!
;    bytevector?
;    get-output-bytevector
;    make-bytevector
;    open-input-bytevector
;    open-output-bytevector
;    read-bytevector
;    read-bytevector!
;    write-bytevector
;
;    : No unicode support at this time
;    peek-u8
;    string->utf8
;    read-u8
;    u8-ready?
;    utf8->string
;    write-u8
;
;    ; No complex or rational numbers at this time
;    complex?
;    rational?
;    rationalize
;
;    ; Need to change how  integer? works, to include floatings points without any decimals
;    denominator
;    numerator
;
;    ; need string ports
;    ; may be able to use POSIX string steams for this, see: open_memstream
;    ; however there may be portability issues with that. looks like BSD and windows don't have it
;    get-output-string
;    open-input-string
;    open-output-string
;
; for a lot of the following, need begin-splicing, or syntax-rules
;    binary-port?
;    define-values
;    guard
;    import
;    include
;    let*-values
;    let-syntax
;    let-values
;    letrec*
;    letrec-syntax
;    parameterize
;    record?
;    syntax-error
;    syntax-rules
;    textual-port?
;;;;
  )
  (begin
    ;; Features implemented by this Scheme
    (define (features) '(cyclone r7rs exact-closed))

    (define-syntax and
      (er-macro-transformer
       (lambda (expr rename compare)
         (cond ((null? (cdr expr)) #t)
               ((null? (cddr expr)) (cadr expr))
               (else (list (rename 'if) (cadr expr)
                           (cons (rename 'and) (cddr expr))
                           #f))))))
    (define-syntax or
      (er-macro-transformer
        (lambda (expr rename compare)
          (cond ((null? (cdr expr)) #f)
                ((null? (cddr expr)) (cadr expr))
                (else
                 (list (rename 'let) (list (list (rename 'tmp) (cadr expr)))
                       (list (rename 'if) (rename 'tmp)
                             (rename 'tmp)
                             (cons (rename 'or) (cddr expr)))))))))
    (define-syntax let
      (er-macro-transformer
        (lambda (expr rename compare)
          (if (null? (cdr expr)) (error "empty let" expr))
          (if (null? (cddr expr)) (error "no let body" expr))
          ((lambda (bindings)
             (if (list? bindings) #f (error "bad let bindings"))
             (if (every (lambda (x)
                          (if (pair? x) (if (pair? (cdr x)) (null? (cddr x)) #f) #f))
                        bindings)
                 ((lambda (vars vals)
                    (if (symbol? (cadr expr))
                        `((,(rename 'lambda) ,vars
                           (,(rename 'letrec) ((,(cadr expr)
                                                (,(rename 'lambda) ,vars
                                                 ,@(cdr (cddr expr)))))
                            (,(cadr expr) ,@vars)))
                          ,@vals)
                        `((,(rename 'lambda) ,vars ,@(cddr expr)) ,@vals)))
                  (map car bindings)
                  (map cadr bindings))
                 (error "bad let syntax" expr)))
           (if (symbol? (cadr expr)) (car (cddr expr)) (cadr expr))))))
    (define-syntax let*
      (er-macro-transformer
        (lambda (expr rename compare)
          (if (null? (cdr expr)) (error "empty let*" expr))
          (if (null? (cddr expr)) (error "no let* body" expr))
          (if (null? (cadr expr))
              `(,(rename 'let) () ,@(cddr expr))
              (if (if (list? (cadr expr))
                      (every
                       (lambda (x)
                         (if (pair? x) (if (pair? (cdr x)) (null? (cddr x)) #f) #f))
                       (cadr expr))
                      #f)
                  `(,(rename 'let) (,(caar (cdr expr)))
                    (,(rename 'let*) ,(cdar (cdr expr)) ,@(cddr expr)))
                  (error "bad let* syntax"))))))
    (define-syntax letrec 
      (er-macro-transformer
        (lambda (exp rename compare)
          (let* ((bindings  (cadr exp)) ;(letrec->bindings exp)
                 (namings   (map (lambda (b) (list (car b) #f)) bindings))
                 (names     (map car (cadr exp))) ;(letrec->bound-vars exp)
                 (sets      (map (lambda (binding) 
                                   (cons 'set! binding))
                                 bindings))
                 (args      (map cadr (cadr exp)))) ;(letrec->args exp)
            `(let ,namings
               (begin ,@(append sets (cddr exp)))))))) ;(letrec->exp exp)
;; NOTE: chibi uses the following macro. turns vars into defines?
;;(define-syntax letrec
;;  (er-macro-transformer
;;   (lambda (expr rename compare)
;;     ((lambda (defs)
;;        `((,(rename 'lambda) () ,@defs ,@(cddr expr))))
;;      (map (lambda (x) (cons (rename 'define) x)) (cadr expr))))))
    (define-syntax begin 
      (er-macro-transformer
        (lambda (exp rename compare)
          (define (singlet? l)
            (and (list? l)
                 (= (length l) 1)))
          
          (define (dummy-bind exps)
            (cond
              ((singlet? exps)  (car exps))
              
              ; JAE - should be fine until CPS phase
              ((pair? exps)
               `((lambda ()
                 ,@exps)))))
              ;((pair? exps)     `(let (($_ ,(car exps)))
              ;                    ,(dummy-bind (cdr exps))))))
          (dummy-bind (cdr exp)))))
    (define-syntax cond-expand
      (er-macro-transformer
        ;; Based on the cond-expand macro from Chibi scheme
        (lambda (expr rename compare)
          (define (check x)
            (if (pair? x)
                (case (car x)
                  ((and) (every check (cdr x)))
                  ((or) (any check (cdr x)))
                  ((not) (not (check (cadr x))))
                  ;((library) (eval `(find-module ',(cadr x)) (%meta-env)))
                  (else (error "cond-expand: bad feature" x)))
                (memq x (features))))
          (let expand ((ls (cdr expr)))
            (cond ((null? ls))  ; (error "cond-expand: no expansions" expr)
                  ((not (pair? (car ls))) (error "cond-expand: bad clause" (car ls)))
                  ((eq? 'else (caar ls)) ;(identifier->symbol (caar ls)))
                   (if (pair? (cdr ls))
                       (error "cond-expand: else in non-final position")
                       `(,(rename 'begin) ,@(cdar ls))))
                  ((check (caar ls)) `(,(rename 'begin) ,@(cdar ls)))
                  (else (expand (cdr ls))))))))
    (define-syntax cond
      (er-macro-transformer
          (lambda (expr rename compare)
            (if (null? (cdr expr))
                #f ;(if #f #f)
                ((lambda (cl)
                   (if (compare (rename 'else) (car cl))
                       (if (pair? (cddr expr))
                           (error "non-final else in cond" expr)
                           (list (cons (rename 'lambda) (cons '() (cdr cl)))))
                       (if (if (null? (cdr cl)) #t (compare (rename '=>) (cadr cl)))
                           (list (list (rename 'lambda) (list (rename 'tmp))
                                       (list (rename 'if) (rename 'tmp)
                                             (if (null? (cdr cl))
                                                 (rename 'tmp)
                                                 (list (car (cddr cl)) (rename 'tmp)))
                                             (cons (rename 'cond) (cddr expr))))
                                 (car cl))
                           (list (rename 'if)
                                 (car cl)
                                 (list (cons (rename 'lambda) (cons '() (cdr cl))))
                                 (cons (rename 'cond) (cddr expr))))))
                 (cadr expr))))))
    (define-syntax case
      (er-macro-transformer
          (lambda (expr rename compare)
            (define (body exprs)
              (cond
               ((null? exprs)
                (rename 'tmp))
               ((compare (rename '=>) (car exprs))
                `(,(cadr exprs) ,(rename 'tmp)))
               (else
                `(,(rename 'begin) ,@exprs))))
            (define (clause ls)
              (cond
               ((null? ls) #f)
               ((compare (rename 'else) (caar ls))
                (body (cdar ls)))
               ((and (pair? (car (car ls))) (null? (cdr (car (car ls)))))
                `(,(rename 'if) (,(rename 'eqv?) ,(rename 'tmp)
                                 (,(rename 'quote) ,(car (caar ls))))
                  ,(body (cdar ls))
                  ,(clause (cdr ls))))
               (else
                `(,(rename 'if) (,(rename 'memv) ,(rename 'tmp)
                                 (,(rename 'quote) ,(caar ls)))
                  ,(body (cdar ls))
                  ,(clause (cdr ls))))))
            `(let ((,(rename 'tmp) ,(cadr expr)))
               ,(clause (cddr expr))))))
    (define-syntax when
      (er-macro-transformer
        (lambda (exp rename compare)
          (if (null? (cdr exp)) (error "empty when" exp))
          (if (null? (cddr exp)) (error "no when body" exp))
          `(if ,(cadr exp)
               ((lambda () ,@(cddr exp)))
               #f))))
    (define-syntax unless
      (er-macro-transformer
        (lambda (exp rename compare)
          (if (null? (cdr exp)) (error "empty unless" exp))
          (if (null? (cddr exp)) (error "no unless body" exp))
          `(if ,(cadr exp)
               #f
               ((lambda () ,@(cddr exp)))))))
  (define-syntax do
    (er-macro-transformer
     (lambda (expr rename compare)
       (let* ((body
               `(,(rename 'begin)
                 ,@(cdr (cddr expr))
                 (,(rename 'lp)
                  ,@(map (lambda (x)
                           (if (pair? (cddr x))
                               (if (pair? (cdr (cddr x)))
                                   (error "too many forms in do iterator" x)
                                   (car (cddr x)))
                               (car x)))
                         (cadr expr)))))
              (check (car (cddr expr)))
              (wrap
               (if (null? (cdr check))
                   `(,(rename 'let) ((,(rename 'tmp) ,(car check)))
                     (,(rename 'if) ,(rename 'tmp)
                      ,(rename 'tmp)
                      ,body))
                   `(,(rename 'if) ,(car check)
                     (,(rename 'begin) ,@(cdr check))
                     ,body))))
         `(,(rename 'let) ,(rename 'lp)
           ,(map (lambda (x) (list (car x) (cadr x))) (cadr expr))
           ,wrap)))))
    (define-syntax quasiquote
      (er-macro-transformer
        ;; Based on the quasiquote macro from Chibi scheme
        (lambda (expr rename compare)
          (define (qq x d)
            (cond
             ((pair? x)
              (cond
               ((compare (rename 'unquote) (car x))
                (if (<= d 0)
                    (cadr x)
                    (list (rename 'list) (list (rename 'quote) 'unquote)
                          (qq (cadr x) (- d 1)))))
               ((compare (rename 'unquote-splicing) (car x))
                (if (<= d 0)
                    (list (rename 'cons) (qq (car x) d) (qq (cdr x) d))
                    (list (rename 'list) (list (rename 'quote) 'unquote-splicing)
                          (qq (cadr x) (- d 1)))))
               ((compare (rename 'quasiquote) (car x))
                (list (rename 'list) (list (rename 'quote) 'quasiquote)
                      (qq (cadr x) (+ d 1))))
               ((and (<= d 0) (pair? (car x))
                     (compare (rename 'unquote-splicing) (caar x)))
                (if (null? (cdr x))
                    (cadr (car x))
                    (list (rename 'append) (cadr (car x)) (qq (cdr x) d))))
               (else
                (list (rename 'cons) (qq (car x) d) (qq (cdr x) d)))))
             ((vector? x) (list (rename 'list->vector) (qq (vector->list x) d)))
             ((if (symbol? x) #t (null? x)) (list (rename 'quote) x))
             (else x)))
          (qq (cadr expr) 0))))

    ;; TODO: The whitespace characters are space, tab, line feed, form feed (not in parser yet), and carriage return.
    (define call-with-current-continuation call/cc)
    ;; TODO: this is from r7rs, but is not really good enough by itself
    ;(define (values . things)
    ;  (call/cc
    ;    (lambda (cont) (apply cont things))))
    (define values 
      (lambda args
        (if (and (not (null? args)) (null? (cdr args)))
            (car args)
            (cons (cons 'multiple 'values) args)))) 
    ;; TODO: just need something good enough for bootstrapping (for now)
    ;; does not have to be perfect (this is not, does not handle call/cc or exceptions)
;    (define call-with-values
;      (lambda (producer consumer)
;        (let ((x (producer)))
;          (if ;(magic? x)
;              (and (pair? x) (equal? (car x) (cons 'multiple 'values)))
;              (apply consumer (cdr x))
;              (consumer x)))))

    (define (dynamic-wind before thunk after)
      (before)
      (let ((result (thunk)))
        (after)
        result)
      ;(call-with-values
      ;  thunk
      ;  (lambda (result) ;results
      ;    (after)
      ;    result)))
          ;(apply values results))))
    )
    (define (call-with-port port proc)
      (let ((result (proc port)))
        (close-port port)
        result))
    (define (Cyc-bin-op cmp x lst)
      (cond
        ((null? lst) #t)
        ((cmp x (car lst))
         (Cyc-bin-op cmp (car lst) (cdr lst)))
        (else #f)))
    (define (Cyc-bin-op-char cmp c cs)
      (Cyc-bin-op
        (lambda (x y) 
          (cmp (char->integer x) (char->integer y)))
        c
        cs))
    (define (char=?  c1 c2 . cs) (Cyc-bin-op-char =  c1 (cons c2 cs)))
    (define (char<?  c1 c2 . cs) (Cyc-bin-op-char <  c1 (cons c2 cs)))
    (define (char>?  c1 c2 . cs) (Cyc-bin-op-char >  c1 (cons c2 cs)))
    (define (char<=? c1 c2 . cs) (Cyc-bin-op-char <= c1 (cons c2 cs)))
    (define (char>=? c1 c2 . cs) (Cyc-bin-op-char >= c1 (cons c2 cs)))
    ; TODO: char-ci predicates (in scheme/char library)


    (define (string=? str1 str2)  (equal? (string-cmp str1 str2) 0))
    (define (string<? str1 str2)  (<  (string-cmp str1 str2) 0))
    (define (string<=? str1 str2) (<= (string-cmp str1 str2) 0))
    (define (string>? str1 str2)  (>  (string-cmp str1 str2) 0))
    (define (string>=? str1 str2) (>= (string-cmp str1 str2) 0))
    ; TODO: generalize to multiple arguments: (define (string<? str1 str2 . strs)

    (define (foldl func accum lst)
      (if (null? lst)
        accum
        (foldl func (func (car lst) accum) (cdr lst))))
    (define (foldr func end lst)
      (if (null? lst)
        end
        (func (car lst) (foldr func end (cdr lst)))))
    (define (read-line . port)
      (if (null? port)
        (Cyc-read-line (current-input-port))
        (Cyc-read-line (car port))))
    (define (read-string k . opts)
      (let ((port (if (null? opts)
                      (current-input-port)
                      (car opts))))
        (let loop ((acc '())
                   (i k)
                   (chr #f))
          (cond
            ((eof-object? chr)
             (list->string 
               (reverse acc)))
            ((zero? i)
             (list->string 
               (reverse 
                 (if chr (cons chr acc) acc))))
            (else
             (loop (if chr (cons chr acc) acc)
                   (- i 1)
                   (read-char port)))))))
    (define (flush-output-port . port)
      (if (null? port)
        (Cyc-flush-output-port (current-output-port))
        (Cyc-flush-output-port (car port))))
    (define (write-string str . port)
      (if (null? port)
        (Cyc-display str (current-output-port))
        (Cyc-display str (car port))))
    (define (write-char char . port)
      (if (null? port)
        (Cyc-write-char char (current-output-port))
        (Cyc-write-char char (car port))))
    (define (newline . port) 
      (apply write-char (cons #\newline port)))
    (define (not x) (if x #f #t))
    (define (list? o)
      (define (_list? obj)
        (cond
          ((null? obj) #t)
          ((pair? obj)
           (_list? (cdr obj)))
          (else #f)))
      (if (Cyc-has-cycle? o)
        #t
        (_list? o)))
    (define (zero? n) (= n 0))
    (define (positive? n) (> n 0))
    (define (negative? n) (< n 0))
    ; append accepts a variable number of arguments, per R5RS. So a wrapper
    ; has been provided for the standard 2-argument version of (append).
    ;
    ; We return the given value if less than 2 arguments are given, and
    ; otherwise fold over each arg, appending it to its predecessor. 
    (define (append . lst)
      (define append-2
              (lambda (inlist alist)
                      (foldr (lambda (ap in) (cons ap in)) alist inlist)))
      (if (null? lst)
          lst
          (if (null? (cdr lst))
              (car lst)
              (foldl (lambda (a b) (append-2 b a)) (car lst) (cdr lst)))))
    (define (list . objs)  objs)
    (define (make-list k . fill)
      (letrec ((x (if (null? fill) 
                   #f
                   (car fill)))
               (make
                 (lambda (n obj)
                   (if (zero? n)
                   '()
                   (cons obj (make (- n 1) obj) )))))
      (make k x)))
    (define (list-copy lst)
      (foldr (lambda (x y) (cons x y)) '() lst))
    (define (map func lst)
      (foldr (lambda (x y) (cons (func x) y)) '() lst))
    (define (for-each f lst)
      (cond
       ((null? lst) #t)
       (else
         (f (car lst))
         (for-each f (cdr lst)))))
; TODO:
;(define (vector-map fnc . vargs)
;    (let ((ls (map vector->list v vargs)))
;        (list->vector
;            (apply map
;                   (cons fnc ls)))))
;
;(define (vector-for-each fnc . vargs)
;    (let ((ls (map vector->list vargs)))
;        (apply for-each
;               (cons fnc ls))))
    (define (list-tail lst k) 
      (if (zero? k)
        lst
        (list-tail (cdr lst) (- k 1))))
    (define (list-ref lst k)  (car (list-tail lst k)))
    (define (list-set! lst k obj)
      (let ((kth (list-tail lst k)))
        (set-car! kth obj)))
    (define (reverse lst)   (foldl cons '() lst))

    (define (vector . objs) (list->vector objs))
    (define (vector->list vec . opts)
      (letrec ((len (vector-length vec))
               (start (if (> (length opts) 0) (car opts) 0))
               (end (if (> (length opts) 1) (cadr opts) len))
               (loop (lambda (i lst)
                       (if (= i end)
                           (reverse lst)
                           (loop (+ i 1) 
                                 (cons (vector-ref vec i) lst))))))
        (loop start '())))
    (define (vector->string vec . opts)
      (let ((lst (apply vector->list (cons vec opts))))
        (list->string lst)))
    (define (string->list str . opts)
      (letrec ((len (string-length str))
               (start (if (> (length opts) 0) (car opts) 0))
               (end (if (> (length opts) 1) (cadr opts) len))
               (loop (lambda (i lst)
                       (if (= i end)
                           (reverse lst)
                           (loop (+ i 1) 
                                 (cons (string-ref str i) lst))))))
        (loop start '())))
    ;; TODO: need to extend string->list to take optional start/end args, 
    ;; then modify this function to work with optional args, too
    (define (string->vector str . opts)
      (list->vector
        (string->list str)))
    (define (string-copy str . opts)
      (letrec ((len (string-length str))
               (start (if (> (length opts) 0) (car opts) 0))
               (end (if (> (length opts) 1) (cadr opts) len)))
        (substring str start end)))
    (define (string-copy! to at from . opts)
      (letrec ((len (string-length from))
               (start (if (> (length opts) 0) (car opts) 0))
               (end (if (> (length opts) 1) (cadr opts) len))
               (loop (lambda (i-at i-from)
                       (cond
                        ((= i-from end) to)
                        (else
                          (string-set! to i-at (string-ref from i-from))
                          (loop (+ i-at 1) (+ i-from 1)))))))
        (loop at start)))
    (define (string-fill! str fill . opts)
      (letrec ((len (string-length str))
               (start (if (> (length opts) 0) (car opts) 0))
               (end (if (> (length opts) 1) (cadr opts) len))
               (loop (lambda (i)
                       (cond
                        ((= i end) str)
                        (else
                          (string-set! str i fill)
                          (loop (+ i 1)))))))
        (loop start)))
    (define (string-map func str)
      (list->string (map func (string->list str))))
    (define (string-for-each func str)
      (for-each func (string->list str)))
    (define (vector-map func vec)
      (list->vector (map func (vector->list vec)))) 
    (define (vector-for-each func vec)
      (for-each func (vector->list vec)))
    (define (vector-append . vecs)
      (list->vector
        (apply append (map vector->list vecs))))
    (define (vector-copy vec . opts)
      (letrec ((len (vector-length vec))
               (start (if (> (length opts) 0) (car opts) 0))
               (end (if (> (length opts) 1) (cadr opts) len))
               (loop (lambda (i new-vec)
                       (cond
                        ((= i end)
                         new-vec)
                        (else
                           (vector-set! new-vec i (vector-ref vec i))
                           (loop (+ i 1) new-vec))))))
        (loop start (make-vector (- end start) #f))))
    ;; TODO: does not quite meet r7rs spec, should check if vectors overlap
    (define (vector-copy! to at from . opts)
      (letrec ((len (vector-length from))
               (start (if (> (length opts) 0) (car opts) 0))
               (end (if (> (length opts) 1) (cadr opts) len))
               (loop (lambda (i-at i-from)
                       (cond
                        ((= i-from end) to)
                        (else
                          (vector-set! to i-at (vector-ref from i-from))
                          (loop (+ i-at 1) (+ i-from 1)))))))
        (loop at start)))
    ;; TODO: this len/start/end/loop pattern is common, could use a macro for it
    (define (vector-fill! vec fill . opts)
      (letrec ((len (vector-length vec))
               (start (if (> (length opts) 0) (car opts) 0))
               (end (if (> (length opts) 1) (cadr opts) len))
               (loop (lambda (i)
                       (cond
                        ((= i end) vec)
                        (else
                          (vector-set! vec i fill)
                          (loop (+ i 1)))))))
        (loop start)))

    (define (boolean=? b1 b2 . bs)
      (Cyc-obj=? boolean? b1 (cons b2 bs)))
    (define (symbol=? sym1 sym2 . syms)
      (Cyc-obj=? symbol? sym1 (cons sym2 syms)))
    (define (Cyc-obj=? type? obj objs)
      (and
        (type? obj)
        (call/cc
          (lambda (return)
            (for-each 
              (lambda (o)
                (if (not (eq? o obj))
                  (return #f)))
              objs)
              #t))))
    (define (string . chars)
      (list->string chars))
    (define (make-string k . fill)
      (let ((fill* (if (null? fill)
                      '(#\space)
                      fill)))
        (list->string
          (apply make-list (cons k fill*)))))
    (define (make-parameter init . o)
      (let* ((converter
               (if (pair? o) (car o) (lambda (x) x)))
             (value (converter init)))
        (lambda args
          (cond
            ((null? args)
             value)
            ((eq? (car args) '<param-set!>)
             (set! value (cadr args)))
            ((eq? (car args) '<param-convert>)
             converter)
           (else
             (error "bad parameter syntax"))))))
    (define current-output-port
      (make-parameter (Cyc-stdout)))
    (define current-input-port
      (make-parameter (Cyc-stdin)))
    (define current-error-port
      (make-parameter (Cyc-stderr)))
    (define (error msg . args)
      (raise (cons msg args)))
    (define (raise obj)
      ((Cyc-current-exception-handler) 
        (cons 'raised (if (pair? obj) obj (list obj)))))
    (define (raise-continuable obj)
      ((Cyc-current-exception-handler) 
        (cons 'continuable (if (pair? obj) obj (list obj)))))
    (define (with-exception-handler handler thunk)
      (let ((result #f)
            (my-handler 
              (lambda (obj)
                (let ((result #f)
                      (continuable? (and (pair? obj) 
                                         (equal? (car obj) 'continuable))))
                  ;; Unregister this handler since it is no longer needed
                  (Cyc-remove-exception-handler)
                  (set! result (handler (cdr obj))) ;; Actual handler
                  (if continuable?
                      result
                      (error "exception handler returned"))))))
      ;; No cond-expand below, since this is part of our internal lib
      (Cyc-add-exception-handler my-handler)
      (set! result (thunk))
      (Cyc-remove-exception-handler) ; Only reached if no ex raised
      result))
    (define-c Cyc-add-exception-handler
      "(void *data, int argc, closure _, object k, object h)"
      " gc_thread_data *thd = (gc_thread_data *)data;
        make_cons(c, h, thd->exception_handler_stack);
        thd->exception_handler_stack = &c;
        return_closcall1(data, k, &c); ")
    (define-c Cyc-remove-exception-handler
      "(void *data, int argc, closure _, object k)"
      " gc_thread_data *thd = (gc_thread_data *)data;
        if (thd->exception_handler_stack) {
          thd->exception_handler_stack = cdr(thd->exception_handler_stack);
        }
        return_closcall1(data, k, thd->exception_handler_stack); ")

  ;; Simplified versions of every/any from SRFI-1
  (define (any pred lst)
    (let any* ((l (map pred lst)))
        (cond
          ((null? l) #f) ; Empty list
          ((car l)   #t) ; Done
          (else 
             (any* (cdr l))))))
  (define (every pred lst)
    (let every* ((l (map pred lst)))
        (cond
          ((null? l) #t) ; Empty list
          ((car l)
             (every* (cdr l)))
          (else 
             #f))))

  (define-c floor
    "(void *data, int argc, closure _, object k, object z)"
    " return_exact_double_op(data, k, floor, z); ")
  (define-c ceiling
    "(void *data, int argc, closure _, object k, object z)"
    " return_exact_double_op(data, k, ceil, z); ")
  (define-c truncate
    "(void *data, int argc, closure _, object k, object z)"
    " return_exact_double_op(data, k, (int), z); ")
  (define-c round
    "(void *data, int argc, closure _, object k, object z)"
    " return_exact_double_op(data, k, round, z); ")
  (define exact truncate)
  (define-c inexact
    "(void *data, int argc, closure _, object k, object z)"
    " return_inexact_double_op(data, k, (double), z); ")
  (define-c abs
    "(void *data, int argc, closure _, object k, object num)"
    " Cyc_check_num(data, num);
      if (type_of(num) == integer_tag) {
        make_int(i, abs(((integer_type *)num)->value));
        return_closcall1(data, k, &i);
      } else {
        make_double(d, fabs(((double_type *)num)->value));
        return_closcall1(data, k, &d);
      } ")
  ;; Apparently C % is actually the remainder, not modulus
  (define-c remainder
    "(void *data, int argc, closure _, object k, object num1, object num2)"
    " int i, j;
      Cyc_check_num(data, num1);
      Cyc_check_num(data, num2);
      if (type_of(num1) == integer_tag) { 
        i = ((integer_type *)num1)->value; 
      } else if (type_of(num1) == double_tag) { 
        i = ((double_type *)num1)->value; 
      }
      if (type_of(num2) == integer_tag) { 
        j = ((integer_type *)num2)->value; 
      } else if (type_of(num2) == double_tag) { 
        j = ((double_type *)num2)->value; 
      }
      {
        make_int(result, i % j);
        return_closcall1(data, k, &result); 
      }")
  ;; From chibi scheme. Cannot use C % operator
  (define (modulo a b)
    (let ((res (remainder a b)))
      (if (< b 0)
        (if (<= res 0) res (+ res b))
        (if (>= res 0) res (+ res b)))))
  (define (odd? num)   (= (modulo num 2) 1))
  (define (even? num)  (= (modulo num 2) 0))
  (define (exact-integer? num)
    (and (exact? num) (integer? num)))
  (define-c exact?
    "(void *data, int argc, closure _, object k, object num)"
    " Cyc_check_num(data, num);
      if (type_of(num) == integer_tag)
        return_closcall1(data, k, boolean_t);
      return_closcall1(data, k, boolean_f); ")
  (define (inexact? num) (not (exact? num)))
  (define (max first . rest) (foldl (lambda (old new) (if (> old new) old new)) first rest))
  (define (min first . rest) (foldl (lambda (old new) (if (< old new) old new)) first rest))
  ; Implementations of gcd and lcm using Euclid's algorithm
  ;
  ; Also note that each form is written to accept either 0 or
  ; 2 arguments, per R5RS. This could probably be generalized
  ; even further, if necessary.
  ;
  (define gcd gcd/entry)
  (define lcm lcm/entry)
  ; Main GCD algorithm
  (define (gcd/main a b)
    (if (= b 0)
      (abs a)
      (gcd/main b (modulo a b))))

  ; A helper function to reduce the input list
  (define (gcd/entry . nums)
    (if (eqv? nums '())
      0
      (foldl gcd/main (car nums) (cdr nums))))

  ; Main LCM algorithm
  (define (lcm/main a b)
    (abs (/ (* a b) (gcd/main a b))))

  ; A helper function to reduce the input list
  (define (lcm/entry . nums)
    (if (eqv? nums '())
      1
      (foldl lcm/main (car nums) (cdr nums))))
  ;; END gcd lcm

  ;; TODO: possibly not correct, just a placeholder
  (define quotient /)

  (define truncate-quotient quotient)
  (define truncate-remainder remainder)
  (define (truncate/ n m)
    (values (truncate-quotient n m) (truncate-remainder n m)))
  
  (define (floor-quotient n m)
    (let ((res (floor (/ n m))))
      (if (and (exact? n) (exact? m))
          (exact res)
          res)))
  (define (floor-remainder n m)
    (- n (* m (floor-quotient n m))))
  (define (floor/ n m)
    (values (floor-quotient n m) (floor-remainder n m)))
  (define (square z) (* z z))
  (define-c expt
    "(void *data, int argc, closure _, object k, object z1, object z2)"
    " make_double(d, 0.0);
      Cyc_check_num(data, z1);
      Cyc_check_num(data, z2);
      d.value = pow( unbox_number(z1), unbox_number(z2) );
      return_closcall1(data, k, &d); ")
  (define-c eof-object
    "(void *data, int argc, closure _, object k)"
    " return_closcall1(data, k, Cyc_EOF); ")
  (define-c input-port?
    "(void *data, int argc, closure _, object k, object port)"
    " port_type *p = (port_type *)port;
      Cyc_check_port(data, port);
      return_closcall1(
        data, 
        k, 
       (p->mode == 1) ? boolean_t : boolean_f); ")
  (define-c output-port?
    "(void *data, int argc, closure _, object k, object port)"
    " port_type *p = (port_type *)port;
      Cyc_check_port(data, port);
      return_closcall1(
        data, 
        k, 
       (p->mode == 0) ? boolean_t : boolean_f); ")
  (define-c input-port-open?
    "(void *data, int argc, closure _, object k, object port)"
    " port_type *p = (port_type *)port;
      Cyc_check_port(data, port);
      return_closcall1(
        data, 
        k, 
       (p->mode == 1 && p->fp != NULL) ? boolean_t : boolean_f); ")
  (define-c output-port-open?
    "(void *data, int argc, closure _, object k, object port)"
    " port_type *p = (port_type *)port;
      Cyc_check_port(data, port);
      return_closcall1(
        data, 
        k, 
       (p->mode == 0 && p->fp != NULL) ? boolean_t : boolean_f); ")
))
