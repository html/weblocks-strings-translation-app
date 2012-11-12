(in-package :weblocks-strings-translation-app)

(defvar *translated-table* nil)
(defvar *translation-callbacks* nil)

(defparameter *languages-supported* '(:en :ru :uk))
(defparameter *default-language* :en)

(defmacro %current-language ()
  `(webapp-session-value 'current-language weblocks::*session* (weblocks::find-app 'weblocks-strings-translation-app)))

(defun current-language ()
  (or (and (boundp 'hunchentoot:*session*) (%current-language)) *default-language*))

(defun set-language (new-lang)
  (when (find (string-downcase new-lang) (mapcar #'string-downcase *languages-supported*) :test #'string=)
    (if (boundp 'hunchentoot:*session*)
      (setf (%current-language) (intern (string-upcase new-lang) "KEYWORD"))
      (setf *default-language* (intern (string-upcase new-lang) "KEYWORD")))
    
    t))

(defclass translated-string ()
  ((value 
     :type string 
     :initarg :value 
     :accessor translated-string-value)))

(defmethod print-object ((object translated-string) stream)
  (write-string (translated-string-value object) stream))

(defun log-translation-missing (string args)
  #+l(format t "Translation is missing for string /~A/ and scope ~A" string args)
  ; TODO: move this into firephp package
  (when (and (find-package :firephp) (boundp 'hunchentoot:*reply*)) 
    (funcall (symbol-function (intern "FB" "FIREPHP")) "Translation is missing for string" string args))
  string)

(defun get-translated-string (string &rest args)
  (when *default-store*
    (let* ((values (find-by-values 
                     'translation-string
                     :value string))
           (translation-string (or (first values)
                                   (persist-object *default-store* (make-instance 'translation-string :value string :active t))))
           (search-conditions (list :scope (cons args #'equal) 
                                    :translation-string translation-string 
                                    :active t))
           (translation (or 
                          (apply #'first-by-values (list* 'translation search-conditions)) 
                          (progn
                            (setf (getf search-conditions :active) nil)
                            (or 
                              (apply #'first-by-values (list* 'translation  search-conditions))                             
                              (progn
                                (setf (getf search-conditions :scope) args)
                                (log-translation-missing string args)
                                (persist-object *default-store* (apply #'make-instance 
                                                                       (list* 'translation 
                                                                              (append search-conditions 
                                                                                      (if (equal 
                                                                                            (getf (getf search-conditions :scope) :lang)
                                                                                            (current-language)) 
                                                                                        (list :value string :active t)
                                                                                        (list :value "Untranslated" :active nil)))))))))))) 
      (setf (slot-value translation-string 'time-last-used) (get-universal-time)) 
      (slot-value translation 'weblocks-strings-translation-app::value))))

; Internationalization
; Stolen from i18n
(defun read-lisp-string (input)
  (with-output-to-string (output)
    (loop
      (let ((char (read-char input)))
        (case char
          (#\\
           (setf char (read-char input)))
          (#\"
           (return)))
        (write-char char output)))))

(defun translate (string &rest args)
  (if (and (find-package :firephp) (boundp 'hunchentoot:*reply*)) 
    (funcall (symbol-function (intern "FB" "FIREPHP")) "Trying to translate" string args))

  (when (zerop (length string))
    (return-from translate string))

  (if (find string *translated-table* :test #'string=)
    string
    (let* ((splitted-str (cl-ppcre:split "(\\$[^\\$]+\\$)" (get-translated-string string :lang (current-language)) :with-registers-p t))
           (return-value 
             (format nil "~{~A~}" 
                     (prog1
                       (loop for i in splitted-str collect
                             (or 
                               (cl-ppcre:register-groups-bind (value)
                                                              ("\\$(.*)\\$" i)
                                                              (and value
                                                                   (let* ((key (read-from-string (string-upcase (format nil ":~A" value))))
                                                                          (value (getf args key)))
                                                                     (unless key 
                                                                       (error (format nil "Need key ~A for translation" key)))
                                                                     (unless value 
                                                                       (error (format nil "Need value for key ~A for translation" key)))
                                                                     (and 
                                                                       (progn 
                                                                         (remf args key)
                                                                         value)))))
                               i))
                       (when args
                         (error (format nil "Some keys do not correspond to their translate string value ~A" args))))))
           (translated-string return-value))
      (push translated-string *translated-table*)
      translated-string)))

(set-dispatch-macro-character #\# #\l
                              #'(lambda (stream char1 char2)
                                  (declare (ignore char1 char2))
                                  (let ((first-character (read-char stream)))
                                    (if (char= first-character #\")
                                      `(translate ,(read-lisp-string stream))
                                      (progn
                                        (unread-char first-character stream)
                                        `(translate ,@(read stream)))))))

(defmethod view-field-label :around ((view-field inline-view-field))
  (translate (call-next-method)))

(defmethod view-caption ((view data-view))
  (if (slot-value view 'weblocks::caption)
      (translate (slot-value view 'weblocks::caption)) 
      (cl-who:with-html-output-to-string (out)
	(:span :class "action" "Modifying:&nbsp;")
	(:span :class "object" "~A"))))

(defmethod view-caption ((view form-view))
  (if (slot-value view 'weblocks::caption)
      (translate (slot-value view 'weblocks::caption)) 
      (cl-who:with-html-output-to-string (out)
	(:span :class "action" "Modifying:&nbsp;")
	(:span :class "object" "~A"))))

(defmethod render-dataform-data-buttons ((obj data-editor) data)
  "Show the Modify and Close buttons as permitted by OBJ."
  (declare (ignore data))
  (with-html
    (:div :class "submit"
	  (render-link (make-action
			(f_% (setf (dataform-ui-state obj) :form)))
		       (translate "Modify")
		       :class "modify")
	  (when (and (dataform-allow-close-p obj)
		     (dataform-on-close obj))
	    (str "&nbsp;")
	    (render-link (make-action
			  (f_% (funcall (dataform-on-close obj) obj)))
			 "Close"
			 :class "close")))))

(defmethod render-view-field-value ((value null) (presentation text-presentation)
                                                 field view widget obj &rest args
                                                 &key ignore-nulls-p &allow-other-keys)
  (declare (ignore args))
  (if ignore-nulls-p
    (call-next-method)
    (with-html
      (:span :class "value missing" (str (translate "Not Specified"))))))

(push 
  (lambda(&rest args)
    (declare (special *translated-table*))
    (setf *translated-table* nil))
  (request-hook :application :post-render))
