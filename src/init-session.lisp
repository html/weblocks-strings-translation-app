(in-package :weblocks-strings-translation-app)

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
                               :slot 'value)
                             (list 
                               :id :active
                               :caption "Active"
                               :accessor #'translation-string-active-p)))
            grid))))
