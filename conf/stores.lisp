(in-package :weblocks-strings-translation-app)

;;; Multiple stores may be defined. The last defined store will be the
;;; default.
(defstore *weblocks-strings-translation-app-store* :prevalence
  (merge-pathnames (make-pathname :directory '(:relative "data"))
       (asdf-system-directory :weblocks-strings-translation-app)))
