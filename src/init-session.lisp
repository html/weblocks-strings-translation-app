(in-package :weblocks-strings-translation-app)

(defun debug-all-translations-for-string (string)
  (mapcar #'object->simple-plist 
          (find-by-values 'translation 
                          :translation-string (first-by-values 'translation-string :value string))))

(defun save-data (file-name)
  (let ((prevalence-serialized-i18n::*translations* (all-of 'translation)))
    (prevalence-serialized-i18n::save-data file-name))
  t)

;; Define callback function to initialize new sessions
(defun init-user-session (comp)
  (setf (composite-widgets comp)
        (let ((grid (make-instance 'gridedit 
                                   :sort (cons 'time-created :asc)
                                   :data-class 'translation-string 
                                   :view 'translation-table-view 
                                   :item-form-view 'translation-edit-view)))
          (list 
            (make-instance 
              'weblocks-filtering-widget:filtering-widget 
              :dataseq-instance grid
              :form-fields (list 
                             (list 
                               :id :value
                               :caption "Value"
                               :slot 'prevalence-serialized-i18n::value)
                             (list 
                               :id :active
                               :caption "Active"
                               :accessor #'translation-string-active-p)))
            grid))))
