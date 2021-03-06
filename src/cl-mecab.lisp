(in-package :cl-user)
(defpackage cl-mecab
  (:use :cl)
  (:import-from :cffi
                #:define-foreign-library
                #:defcstruct
                #:defcenum
                #:defcfun
                #:use-foreign-library)
  (:import-from :split-sequence
                #:split-sequence)
  (:export #:make-mecab
           #:with-mecab
           #:parse
           #:parse*))
(in-package :cl-mecab)


(define-foreign-library libmecab
    (:darwin (:or "libmecab.2.dylib" "libmecab.dylib"))
    (:unix "libmecab.so")
    (:windows "libmecab.dll"))

(use-foreign-library libmecab)

(defcfun ("mecab_new2" %mecab_new2%) :pointer
  (arg :string))

(defcfun ("mecab_sparse_tostr" %mecab_sparse_tostr%) :string
  (mecab :pointer) ; mecab_t
  (str :string))

(defcfun ("mecab_destroy" %mecab_destroy%) :void
  (mecab :pointer)) ; mecab_t


(defvar *mecab*)

(defun make-mecab (&optional (option ""))
  (%mecab_new2% option))

(defmacro with-mecab ((&optional (option "")) &body body)
  `(let ((*mecab* (make-mecab ,option)))
      (unwind-protect
           (progn
             (%mecab_sparse_tostr% *mecab* "") ; avoiding MeCab bug
             ,@body)
        (%mecab_destroy% *mecab*))))

(defun parse (text &optional (*mecab* *mecab*))
  (%mecab_sparse_tostr% *mecab* text))

(defun parse* (text &optional (*mecab* *mecab*))
  (let* ((parse-result (%mecab_sparse_tostr% *mecab* text))
         (lines (split-sequence #\Newline parse-result)))

    (loop
       for line in lines
       for tab-splited = (split-sequence #\Tab line)
       while (= 2 (length tab-splited))
       collect (cons (first tab-splited)
                     (split-sequence #\, (second tab-splited))))))
