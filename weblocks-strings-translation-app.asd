(defpackage #:weblocks-strings-translation-app-asd
  (:use :cl :asdf))

(in-package :weblocks-strings-translation-app-asd)

(defsystem weblocks-strings-translation-app
     :name "weblocks-strings-translation-app"
     :version "0.1.1"
     :maintainer "Olexiy Zamkoviy"
     :author "Olexiy Zamkoviy"
     :licence "LLGPL"
     :description "weblocks-strings-translation-app"
     :depends-on 
     (:weblocks :weblocks-utils :weblocks-filtering-widget :prevalence-serialized-i18n  
      :weblocks-stores)
     :components ((:file "weblocks-strings-translation-app")
         (:module src 
          :components 
          ((:file "init-session" :depends-on ("views"))
           (:module views 
            :components 
            ((:file "translation"))))
          :depends-on ("weblocks-strings-translation-app"))))
