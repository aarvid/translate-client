;;;; translate-client.lisp
;;;;
;;;; Copyright (c) 2017 andy peterson

(in-package #:translate-client)

;; Based on the Google translation API
;;  https://cloud.google.com/translate/docs/translating-text
;; example uri:
;; https://translation.googleapis.com/language/translate/v2?key=YOUR_KEY_HERE&source=en&target=pt&q=Hello%20world&q=My%20name%20is%20Jeff

(defparameter *uri-scheme* "https"
  "the google translation api scheme")

(defparameter *uri-host* "translation.googleapis.com"
  "the google translation api host")

(defparameter *uri-path* "/language/translate/v2"
  "the google translation api path")

(defvar *google-api-key* "YOUR_API_KEY"
  "the default google cloud api key. You need your own key and should be set in your own code.")

(defparameter *uri-char-limit* 2000
  "google states that the uri must not pass 2000 characters"
; note that by trial and error this number is at least 5000.
  )

(defparameter *source-language* :en
  "the default source language to be translated from. can be a string or keyword.
 must be an ISO-639-1 identifier")

(defparameter *target-language* :pt
  "the target language to be translated to. can be a string or keyword.
 must be an ISO-639-1 identifier")

(defparameter *translation-format* :text
  " the translation format of the translated text.
Must be :html for html or :text for plain-text")

(defun string-ellipsis (str max-length &key cut-point (ellipsis "..."))
  "this returns a string with maximum length max-length.
If the given string is larger than max-length, this returns a string with ellipsis
in the middle at the cut-point.
If cut-point is nil, the ellipsis is in the middle.
If cut-point is zero, negative or :front, the ellipsis is at the beginning.
If cut-point is too large or :back, the ellipsis is at the end. "
  (let ((lenstr (length str)))
    (if (<= lenstr max-length)
        str
        (let* ((ellen (length ellipsis))
               (cut (cond ((or (and (keywordp cut-point)
                                    (eq cut-point :front))
                               (non-positive-fixnum-p cut-point))
                           0)
                          ((positive-fixnum-p cut-point)
                           (min cut-point (- max-length ellen)))
                          ((and (keywordp cut-point)
                                (eq cut-point :back))
                           (- max-length ellen))
                          (t (ceiling (- max-length ellen) 2)))))
          (concatenate 'string
                       (subseq str 0 cut)
                       ellipsis
                       (subseq str (- lenstr (- max-length cut ellen)) lenstr))))))

(define-condition google-uri-character-limit-error (error)
  ((google-uri :initarg :google-uri
               :reader google-uri-reader))
  (:report (lambda (condition stream)
             (format stream "URI is greater than allowed limit of ~a characters:~%~a"
                     *uri-char-limit*
                     (string-ellipsis (quri:render-uri (google-uri-reader condition)) 80)))))

(defun translate-uri (strings &key (source *source-language*)
                                   (target *target-language*)
                                   (api-key *google-api-key*)
                                   (format  *translation-format*))
  "create google uri to translates string(s) from the source language to the target language
The parameter strings is either a string or a list of strings.
Parameters source and target are strings or keywords and must be ISO-639-1 language identifiers.
Api-key is a string and must be a valid google cloud api key.
format needs to be either :html or :text"
  (quri:make-uri :scheme *uri-scheme*
                 :host *uri-host*
                 :path *uri-path*
                 :query (list* (cons "key" api-key)
                               (cons "source" (string source))
                               (cons "target" (string target))
                               (cons "format" (string-downcase (string format)))
                               (mapcar (curry #'cons "q")
                                       (ensure-list strings)))))

(defun encoded-parameter-length (str)
  (+ 3 (length (quri:url-encode str))))

(defun whitespacep (ch)
  (member ch '(#\Space #\Tab #\Linefeed #\Return #\Newline #\Page)))

(defun divide-long-string (str base-length)
  (let* ((enclen (length (quri:url-encode str)))
         (len (length str)))
    (loop for n from (ceiling enclen (- *uri-char-limit* 3 base-length)) to len
          for sublen = (floor len n)
          and end = len
          and substrings = nil do
            (loop while (> end 0)
                  for cut = (max 0 (- end sublen)) do
              (let ((start (or (position-if #'whitespacep str
                                            :start cut :end end)
                               (position-if #'whitespacep str
                                            :start 0 :end cut :from-end t)
                               0)))
                (push (subseq str start end) substrings)
                (setf end start)))
            (if (every (lambda (s)
                         (<= (+ base-length (encoded-parameter-length s)) *uri-char-limit*))
                     substrings)
                (return substrings)))))

(defun divide-into-translation-groups (strings &rest all-keys
                                               &key (source *source-language*)
                                                    (target *target-language*)
                                                    (api-key *google-api-key*)
                                                    (format  *translation-format*))
  "returns a list of lists.  the inner lists must be one of two things:
A list of strings (only) for a single http-request to translate multiple string
or a list of a single list of strings when a single translation string must be
divided into parts"
  (declare (ignore source target api-key format))
  (let* ((base-length (length (render-uri (apply #'translate-uri nil all-keys))))
         (curlen base-length)
         (curgroup nil)
         (groups nil))
    (labels ((save-group ()
               (when curgroup
                 (push (reverse curgroup) groups))
               (setf curgroup nil)
               (setf curlen base-length)))
      (dolist (s (ensure-list strings))
        (let ((len (encoded-parameter-length s)))
          (if (> len *uri-char-limit*)
              (progn (save-group)
                     (push (list (divide-long-string s base-length)) groups))
              (progn
                (when (> (+ len curlen) *uri-char-limit*)
                  (save-group))
                (push s curgroup)
                (incf curlen len)))))
      (when curgroup
        (save-group)))
    (reverse groups)))

(defun json-to-translated-strings (json-str)
  "given the json response from google, return the list of translated strings"
  ;; note that we use alist because the translations are in the order of the uri.
  (mapcar (rcurry #'aget "translatedText")
          (aget (aget (yason:parse json-str :object-as :alist) "data") "translations")))

(defun translate (strings &rest all-keys
                          &key (source *source-language*)
                               (target *target-language*)
                               (api-key *google-api-key*)
                               (format  *translation-format*))
  "translates the string(s) from the source language to the target language.
The parameter strings is either a string or a list of strings to be translated.
Returns
Parameters source and target are strings or keywords and must be ISO-639-1 language identifiers.
Api-key is a string and must be a valid google cloud api key.
format needs to be either :html or :text"
  (declare (ignore source target api-key format))
  (labels ((translate-group (str-group)
             (let ((uri (apply #'translate-uri str-group all-keys)))
               (when (> (length (quri:render-uri uri)) *uri-char-limit*)
                 (error 'google-uri-character-limit-error :google-uri uri ))
               (multiple-value-bind (response-json status)
                   (dexador:get uri)
                 (when (= status 200)
                   (json-to-translated-strings response-json))))))
    (funcall (if (listp strings)
                 #'identity
                 #'car)
             (mapcan (lambda (group)
                       (if (listp (car group))
                           (list (apply #'concatenate 'string
                                        (mapcar (lambda (s) (car (translate-group s)))
                                                (car group))))
                           (translate-group group)))
                     (apply #'divide-into-translation-groups strings all-keys)))))

(defun translate-to-alist (strings &rest all-keys
                                   &key (source *source-language*)
                                        (target *target-language*)
                                        (api-key *google-api-key*)
                                        (format  *translation-format*))
  "similar to translate but returns an association list of translation pairs."
  (declare (ignore source target api-key format))
  (let ((stringlist (ensure-list strings)))
    (mapcar #'cons
            stringlist
            (apply #'translate stringlist all-keys))))
