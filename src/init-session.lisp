(in-package :weblocks-strings-translation-app)

(defun widget-translation-calls (obj)
  "Returns all 'translation' function calls during generation widget translation table"
  (let ((weblocks-translation-function weblocks-util:*translation-function*)
        (translation-calls nil))
    (unwind-protect 
      (progn 
        (setf weblocks-util:*translation-function* 
              (lambda (&rest args)
                (push args translation-calls)
                (first args)))
        (widget-translation-table obj))
      (setf weblocks-util:*translation-function* weblocks-translation-function))
    (remove-duplicates 
      translation-calls 
      :test (lambda (item1 item2)
              (and 
                (string= (car item1) (car item2))
                (prevalence-serialized-i18n::translation-scopes-equalp 
                  (weblocks-i18n-scope->prevalence-serialized-i18n-scope (cdr item1)) 
                  (weblocks-i18n-scope->prevalence-serialized-i18n-scope (cdr item2))))))))

(defun weblocks-i18n-scope->prevalence-serialized-i18n-scope (scope)
  (setf scope (copy-list scope))

  (let ((word-form (cond 
                     ((remf scope :genitive-form-p) 
                      :genitive)
                     ((remf scope :accusative-form-p)
                      :accusative)))
        (count (prog1 
                 (getf scope :items-count)
                 (remf scope :items-count))))

    (setf (getf scope :form) (or (getf scope :form) word-form))
    (setf (getf scope :lang) weblocks:*current-locale*)
    (setf (getf scope :count) (or (getf scope :count) count))

    scope))

(defun find-translation (string scope)
  (first-by-values 
    'translation 
    :translation-string (cons string #'string=)
    :scope (cons 
             (weblocks-i18n-scope->prevalence-serialized-i18n-scope scope)
             #'prevalence-serialized-i18n::translation-scopes-equalp)
    :store *prevalence-serialized-i18n-store*))

(defun debug-widget-translations (widget)
  (lambda/cc (&rest args)
    (do-page 
      (make-widget 
        (lambda (&rest args)
          (with-html 
            (:h1 "Widget strings to translate")
            (render-link 
              (lambda (&rest args)
                (answer (first (widget-children (root-widget)))))
              "back")
            "&nbsp;&nbsp;|&nbsp;&nbsp;"
            (render-link 
              (lambda (&rest args)
                (loop for (string . scope) in (widget-translation-calls widget) 
                      unless (find-translation string scope)
                      do 
                      (persist-object *prevalence-serialized-i18n-store* 
                                      (make-instance 
                                        'translation
                                        :translation-string string
                                        :value string
                                        :active nil
                                        :scope (weblocks-i18n-scope->prevalence-serialized-i18n-scope scope))))
                (do-information "Generated successfully"))
              (format nil "generate translation strings for current language (~A)" weblocks:*current-locale*))
            (:br)
            (:br)
            (:div :style "font-family:monospace"
             "[&#8505;] "
             (:i "Items marked " 
              (:b "Ok") 
              " exist in database as translation records")
             (:br)
             (:br)
             (loop for call in (widget-translation-calls widget) do 
                   (cl-who:htm 
                     (if (find-translation (car call) (cdr call))
                       (cl-who:htm (:b "Ok "))
                       (cl-who:htm (:i "-&nbsp;&nbsp;")))
                     (setf (cdr call) (weblocks-i18n-scope->prevalence-serialized-i18n-scope (cdr call)))
                     (cl-who:esc (prin1-to-string call))
                     (:br)))
             (:br)
             (:h1 "Widget translation table")
             (:dl 
               (loop for (key . value) in (widget-translation-table widget) do 
                   (cl-who:htm 
                     (:dt (cl-who:fmt ":~A" key))
                     (:dd (str value))))))))))))

(defmacro call-with-translation-app (&body body)
  `(weblocks::with-webapp 
     (weblocks::find-app :weblocks-strings-translation-app)
     ,@body))

(defun debug-application-widget-tree (application)
  (weblocks::with-webapp application 
    (weblocks-utils:with-first-active-session
      (when (root-widget)
        (with-html 
          (walk-widget-tree 
            (root-widget)
            (lambda (w d)
              (cl-who:htm 
                (loop repeat d do (cl-who:htm (str "&nbsp;&nbsp;")))
                (cl-who:esc (prin1-to-string w))
                " "
                (call-with-translation-app 
                  (render-link (debug-widget-translations w) "debug translations"))
                (:br)))))))))

;; Define callback function to initialize new sessions
(defun init-user-session (comp)
  (setf (composite-widgets comp)
        (make-navigation 
          "toplevel"
          (list "Translation strings list"
                (let ((grid (make-instance 'gridedit 
                                           :class-store *prevalence-serialized-i18n-store*
                                           :sort (cons 'time-created :asc)
                                           :data-class 'translation 
                                           :view 'translation-table-view 
                                           :item-form-view 'translation-edit-view)))
                  (make-instance 'composite :widgets 
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
                                                      :id :translation-string
                                                      :caption "Translation string"
                                                      :slot 'prevalence-serialized-i18n::translation-string)
                                                    (list 
                                                      :id :active
                                                      :caption "Active"
                                                      :slot 'prevalence-serialized-i18n::active)))
                                   grid)))
                nil
                )
          (list "Debug widget translations"
                (eval 
                  `(make-navigation 
                     "debug page"
                     ,@(loop for i in weblocks::*active-webapps* 
                             collect `(list (weblocks::weblocks-webapp-name ,i)
                                            (make-instance 
                                              'composite 
                                              :widgets (list 
                                                         (lambda (&rest args)
                                                           (with-html 
                                                             (:h1 "Widget tree from last page viewed"))
                                                           (debug-application-widget-tree ,i))))
                                            (attributize-name (weblocks::weblocks-webapp-name ,i))))))
                "debug-translations"))))
