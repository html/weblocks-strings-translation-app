(in-package :weblocks-strings-translation-app)

;; Define callback function to initialize new sessions
(defun init-user-session (comp)
  (setf (composite-widgets comp)
  (list (make-instance 'gridedit 
                       :sort (cons 'time-created :asc)
                       :data-class 'translation-string 
                       :view 'translation-table-view 
                       :item-form-view 'translation-edit-view))))
