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

#+l(find-by-values 'translation :translation-string (first (find-by-values 'translation-string :value "None")) 
                :scope (cons (list :lang :ru) #'prevalence-serialized-i18n::langs-equal))

(defun lang-translation-writer (lang)
  (lambda (value item)
    (let* ((opts (list 'translation 
                       :translation-string item 
                       :scope (cons (list :lang lang) #'prevalence-serialized-i18n::langs-equal)))
           (item (first (apply #'find-by-values opts))))
      (when (not (zerop (length value)))
        (when (not item)
          (setf item (persist-object 
                       *default-store* 
                       (apply #'make-instance 
                              :scope (list :lang lang :active t)))))
        (setf (value item) value)
        (setf (slot-value item 'prevalence-serialized-i18n::active) t)))))

(defmacro capture-weblocks-output (&body body)
  `(let ((*weblocks-output-stream* (make-string-output-stream)))
     ,@body 
     (get-output-stream-string *weblocks-output-stream*)))

(defun/cc delete-translation-action (i)
  (lambda (&rest args)
    (delete-one i)
    (delete-persistent-object *default-store* i)
    (firephp:fb "looks like deleted ~A ~A" (object-id i) i)
    (loop for i in (get-widgets-by-type 'gridedit) do 
          (mark-dirty i :propagate t)
          (firephp:fb i))))

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
         (debug-translations 
           :present-as html
           :reader (lambda (item)
                     (capture-weblocks-output 
                       (with-html 
                         (:ul
                           (loop for i in (find-by-values 'translation :translation-string item) do 
                                 (cl-who:htm 
                                   (:li (str (prin1-to-string (object->simple-plist i)))
                                    (render-link 
                                      (make-action (delete-translation-action i))
                                      "x")))))))))
         (active :present-as checkbox :parse-as predicate))
