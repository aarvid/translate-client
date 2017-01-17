;;;; package.lisp
;;;;
;;;; Copyright (c) 2017 andy peterson

(defpackage #:translate-client
  (:use #:cl #:alexandria #:quri)
  (:import-from #:assoc-utils #:aget)
  (:export #:*uri-scheme*
           #:*uri-host*
           #:*uri-path*
           #:*google-api-key*
           #:*uri-char-limit*
           #:*source-language*
           #:*target-language*
           #:*translation-format*
           #:translate
           #:translate-to-alist))

