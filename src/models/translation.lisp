(in-package :weblocks-strings-translation-app)

(defclass translation-string ()
  ((id)
   (active :initform nil 
           :initarg :active 
           :accessor :translation-string-active-p)
   (value :initform nil :initarg :value) 
   (time-last-used :initform (get-universal-time)) 
   (time-created :initform (get-universal-time))))

(defclass translation ()
  ((id)
   (translation-string 
     :type translation-string 
     :initarg :translation-string 
     :accessor translation-string)
   (value :initform nil 
          :initarg :value 
          :accessor value)
   (scope 
     :initform nil 
     :initarg :scope 
     :accessor scope)
   (active :initform nil 
           :initarg :active 
           :accessor translation-active-p)))

(defmethod translations-count ((obj translation-string))
  (length (find-by-values 'translation :translation-string obj)))

(defmacro define-lang-translation (lang)
  `(defmethod ,(intern (string-upcase (format nil "~A-TRANSLATION" lang))) ((obj translation-string))
     (let ((translation (first (find-by-values 'translation :translation-string obj :scope (cons (list :lang ',lang) #'equal)))))
       (and translation (value translation))))) 

(define-lang-translation en)
(define-lang-translation uk)
(define-lang-translation ru)
