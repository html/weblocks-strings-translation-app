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
         (translations-count :reader #'translations-count))

(defun lang-translation-writer (lang)
  (lambda (value item)
    (let* ((opts (list 'translation 
                       :translation-string item 
                       :scope (list :lang lang)))
           (translation (or (first (apply #'find-by-values opts))
                            (persist-object 
                              *default-store* 
                              (apply #'make-instance (append opts (list :active t))))))) 
           (setf (value translation) value))))

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
         ;(scope :present-as text)
         (active :present-as checkbox :parse-as predicate))
