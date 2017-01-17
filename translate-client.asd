;;;; translate-client.asd
;;;;
;;;; Copyright (c) 2017 andy peterson

(defsystem #:translate-client
  :description "A client to online web-server translators, currently only google translate"
  :author "andy peterson"
  :license "MIT"
  :depends-on (#:alexandria
               #:quri
               #:dexador
               #:assoc-utils
               #:yason)
  :serial t
  :components ((:file "package")
               (:file "translate-client")))

