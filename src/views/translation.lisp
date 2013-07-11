(in-package :weblocks-strings-translation-app)

(defview translation-table-view (:type table :inherit-from '(:scaffold translation-string))
         #+l(translation-string :present-as excerpt 
                             :reader (lambda (item)
                                       (slot-value (translation-string item) 'value)))
         (value :present-as excerpt)
         (active :present-as text :reader (lambda (item)
                                            (when (translation-string-active-p item) "Yes !")))
         (en-translation :reader #'en-translation :present-as excerpt)
         (uk-translation :reader #'uk-translation :present-as excerpt)
         (ru-translation :reader #'ru-translation :present-as excerpt)
         (debug-translations 
           :reader (lambda (item)
                     (format 
                       nil
                       "~{~A<br/>~}"
                       (mapcar 
                         (lambda (item)
                           (prin1-to-string (object->simple-plist item)))
                         (prevalence-serialized-i18n::translation-string-translations item)))) :present-as html)
         (translations-count :reader (lambda (item)
                                       (length (find-by-values 'translation :translation-string item)))))

; Warning, there are 2 copies of this function
(defun get-translation-string-translation-for-lang (translation-string lang number-form)
  (let ((translations)
        (filtered-translations))
    ; First filtering by lang scope
    (setf filtered-translations 
          (loop for i in (prevalence-serialized-i18n::translation-string-translations translation-string) 
                if (equal (getf (prevalence-serialized-i18n::translation-scope i) :lang) lang)
                collect i))

    (unless filtered-translations 
      (return-from get-translation-string-translation-for-lang))

    (setf translations filtered-translations)

    ; Second filtering by number form
    (setf filtered-translations 
          (loop for i in (prevalence-serialized-i18n::translation-string-translations translation-string) 
                if (equal (getf (prevalence-serialized-i18n::translation-scope i) :count) number-form)
                collect i))

    (first filtered-translations)))

(defun lang-translation-writer (lang &optional number-form)
  (lambda (value item)
    (let* ((translation (get-translation-string-translation-for-lang item lang number-form)))
      (when (not (zerop (length value)))
        (when (not translation)
          (setf translation (make-instance 
                              'translation
                              :translation-string item
                              :scope (list :lang lang :count number-form :active t))))
        (setf (value translation) value)
        (setf (getf (prevalence-serialized-i18n::translation-scope translation) :count) number-form)
        (setf (slot-value translation 'prevalence-serialized-i18n::active) t)
        (persist-object *prevalence-serialized-i18n-store* translation)))))

(defmacro capture-weblocks-output (&body body)
  `(let ((*weblocks-output-stream* (make-string-output-stream)))
     ,@body 
     (get-output-stream-string *weblocks-output-stream*)))

(defun/cc delete-translation-action (i)
  (lambda (&rest args)
    (delete-one i :store *prevalence-serialized-i18n-store*)
    (firephp:fb "looks like deleted ~A ~A" (object-id i) i)
    (loop for i in (get-widgets-by-type 'gridedit) do 
          (mark-dirty i :propagate t))))

(defun ru-lang-translation-reader ($count)
  (lambda (translation-string)
    (or 
      (ignore-errors  
        (value (first-by-values  
                 'prevalence-serialized-i18n::translation 
                 :translation-string translation-string
                 :scope (cons 
                          (list 
                            :lang :ru 
                            :count $count)
                          (lambda (item1 item2)
                            (and 
                              (equal (getf item1 :lang) (getf item2 :lang))
                              (equal (getf item1 :count) (getf item2 :count)))))
                 :store *prevalence-serialized-i18n-store*))))))

(defview translation-edit-view (:type form :inherit-from '(:scaffold translation-string))
         #+l(translation-string :present-as text 
                             :reader (lambda (item)
                                       (slot-value (translation-string item) 'value)))
         (value :present-as textarea :writer (lambda (&rest args)))
         (en-translation 
           :present-as textarea 
           :reader #'en-translation
           :writer (lang-translation-writer :en))
         (uk-translation 
           :present-as textarea 
           :reader #'uk-translation
           :writer (lang-translation-writer :uk))
         (ru-translation 
           :present-as textarea 
           :reader #'ru-translation
           :writer (lang-translation-writer :ru))
         (ru-single-translation 
           :present-as textarea 
           :reader  (ru-lang-translation-reader :one)
           :writer (lang-translation-writer :ru :one))
         (ru-few-translation 
           :present-as textarea 
           :reader (ru-lang-translation-reader :few)
           :writer (lang-translation-writer :ru :few))
         (ru-many-translation 
           :present-as textarea 
           :reader (ru-lang-translation-reader :many)
           :writer (lang-translation-writer :ru :many))
         (debug-translations 
           :present-as html
           :reader (lambda (item)
                     (capture-weblocks-output 
                       (with-html 
                         (:ul
                           (loop for i in (prevalence-serialized-i18n::translation-string-translations item) do 
                                 (cl-who:htm 
                                   (:li (str (prin1-to-string (object->simple-plist i)))
                                    (render-link 
                                      (make-action (delete-translation-action i))
                                      "x")))))))))
         (active :present-as checkbox :parse-as predicate))
