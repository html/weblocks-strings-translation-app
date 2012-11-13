(defpackage #:weblocks-strings-translation-app
  (:use :cl :weblocks
        :f-underscore :anaphora 
        :weblocks-utils 
        :prevalence-serialized-i18n)
  (:import-from :hunchentoot #:header-in
                #:set-cookie #:set-cookie* #:cookie-in
                #:user-agent #:referer)
  (:documentation
    "A web application based on Weblocks."))

(in-package :weblocks-strings-translation-app)

(export '(start-weblocks-strings-translation-app stop-weblocks-strings-translation-app))

;; A macro that generates a class or this webapp

(defwebapp weblocks-strings-translation-app
    :prefix "/strings-translation" 
    :description "weblocks-strings-translation-app: A new application"
    :init-user-session 'weblocks-strings-translation-app::init-user-session
    :autostart nil                   ;; have to start the app manually
    :ignore-default-dependencies nil ;; accept the defaults
    :debug t
    )   

;; Top level start & stop scripts

(defmethod weblocks:object-id :around ((obj prevalence-serialized-i18n::translation))
  (slot-value obj 'prevalence-serialized-i18n::id))

(defmethod (setf weblocks:object-id) :around (value (obj prevalence-serialized-i18n::translation))
  (setf (slot-value obj 'prevalence-serialized-i18n::id) value))

(defmethod weblocks:object-id :around ((obj prevalence-serialized-i18n::translation-string))
  (slot-value obj 'prevalence-serialized-i18n::id))

(defmethod (setf weblocks:object-id) :around (value (obj prevalence-serialized-i18n::translation-string))
  (setf (slot-value obj 'prevalence-serialized-i18n::id) value))

(defmethod initialize-instance :after ((obj prevalence-serialized-i18n::translation) &rest args)
  (setf (object-id obj) (prevalence-serialized-i18n::get-next-id-for prevalence-serialized-i18n::*translations*)))

(defun add-translations-data-to-database ()

  (delete-all 'translation)
  (delete-all 'translation-string)

  (loop for i in prevalence-serialized-i18n::*translations* do 
        (persist-object *default-store* i)
        (persist-object *default-store* (translation-string i))))

(defun start-weblocks-strings-translation-app (&rest args &key (store nil) &allow-other-keys)
  "Starts the application by calling 'start-weblocks' with appropriate arguments."

  (add-translations-data-to-database)
  (apply #'start-weblocks args)
  (start-webapp 'weblocks-strings-translation-app)
  (when store 
    (setf *weblocks-strings-translation-app-store* store)))

(defun stop-weblocks-strings-translation-app ()
  "Stops the application by calling 'stop-weblocks'."
  (stop-webapp 'weblocks-strings-translation-app)
  (stop-weblocks))
