(defpackage #:weblocks-strings-translation-app-asd
  (:use :cl :asdf))

(in-package :weblocks-strings-translation-app-asd)

(defsystem weblocks-strings-translation-app
    :name "weblocks-strings-translation-app"
    :version "0.0.1"
    :maintainer ""
    :author ""
    :licence ""
    :description "weblocks-strings-translation-app"
    :depends-on (:weblocks)
    :components ((:file "weblocks-strings-translation-app")
     (:module conf
      :components ((:file "stores"))
      :depends-on ("weblocks-strings-translation-app"))
     (:module src 
      :components ((:file "init-session"))
      :depends-on ("weblocks-strings-translation-app" conf))))
