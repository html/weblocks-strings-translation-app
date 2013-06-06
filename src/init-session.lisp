(in-package :weblocks-strings-translation-app)

(defun debug-all-translations-for-string (string)
  (mapcar #'object->simple-plist 
          (find-by-values 'translation 
                          :translation-string (first-by-values 'translation-string :value string))))

(defun packages-equal (item1 item2)
  (let ((package1 (getf item1 :package))
        (package2 (getf item2 :package)))
    (equal package1 package2)))

;; Define callback function to initialize new sessions
(defun init-user-session (comp)
  (setf (composite-widgets comp)
        (let ((grid (make-instance 'gridedit 
                                   :class-store *prevalence-serialized-i18n-store*
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
