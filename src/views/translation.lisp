(in-package :weblocks-strings-translation-app)

(defview translation-table-view (:type table :inherit-from '(:scaffold translation))
         (prevalence-serialized-i18n::translation-string :present-as text)
         (value :present-as excerpt)
         (active :present-as predicate))

(defview translation-edit-view (:type form :inherit-from '(:scaffold translation))
         (prevalence-serialized-i18n::translation-string :present-as text)
         (value :present-as textarea)
         (prevalence-serialized-i18n::scope :present-as text)
         (active 
           :reader (lambda (item)
                     t)
           :present-as checkbox 
           :parse-as predicate))
