(defpackage #:weblocks-strings-translation-app
  (:use :cl :weblocks
        :f-underscore :anaphora 
        :weblocks-utils 
        :weblocks-stores
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

(defun start-weblocks-strings-translation-app (&rest args &key &allow-other-keys)
  "Starts the application by calling 'start-weblocks' with appropriate arguments."

  (apply #'start-weblocks (alexandria:remove-from-plist args))
  (start-webapp 'weblocks-strings-translation-app))

(defun stop-weblocks-strings-translation-app ()
  "Stops the application by calling 'stop-weblocks'."
  (stop-webapp 'weblocks-strings-translation-app)
  (stop-weblocks))
