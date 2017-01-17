Translate Client is a library for interfacing with an http-protocol web-server that handles text translation between languages. List of Web Servers:

  Google Translate
    Website: https://cloud.google.com/translate/docs/translating-text
    Requirements: Google Cloud service API Key
    Status: Functioning
  Microsoft Translator
    Website: http://docs.microsofttranslator.com/text-translate.html
    Requirements: azure account and key
    Status: Future development 

This project depends on Alexandria (utilities), Dexador (http client), quri (uri generator), yason (json parsing) and assoc-utils. If you prefer to use a different http client, json library or uri generator, please open an issue.

This project is under the MIT license.

The goal of this project is to provide a common lisp client interface to web-server translation services while at the same time overcoming the limitations of these services.  For example, Google Translate has a stated 2000 character limit for the entire HTTP Request (though the real limit seems somewhere above 5000).  If the requested translation(s) surpass this limit, the software will seemlessly divide the translations into multiple requests.

Exported symbols:
  Parameters:
    *uri-scheme* : the google translation api scheme
    *uri-host* : the google translation api host
    *uri-path* : the google translation api path
    *google-api-key* : the default google cloud api key. You need your own key
      and should be set in your own code.
    *uri-char-limit* : google states that the uri must not pass 2000 characters
    *source-language* : the default source language to be translated from.
      can be a string or keyword. must be an ISO-639-1 identifier
    *target-language* : the target language to be translated to. can be a
      string or keyword. must be an ISO-639-1 identifier
    *translation-format* : the translation format of the translated text.
      Must be :html for html or :text for plain-text
  Functions:  
    translate : (strings &key source target api-key format)
      Translates the string(s) from one language to another.
      Returns a translated string if given a string
        or the list of translated strings if given a list.
      The parameter strings is either a string or a list of strings.
      Keys source and target are strings or keywords and must be ISO-639-1
        language identifiers. Defaults to *source-language* and *target-language*
      Key api-key is a string and must be a valid google cloud api key.
        Defaults to *google-api-key*
      Key format needs to be either :html or :text
        Defaults to *translation-format*
    translate-to-alist : (strings &key source target api-key format)
      similar to translate but returns an association list of translation pairs.
