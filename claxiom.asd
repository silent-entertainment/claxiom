;;;; claxiom.asd

(asdf:defsystem #:claxiom
  :serial t
  :description "A notebook-style in-browser editor for Common Lisp"
  :author "Inaimathi <leo.zovic@gmail.com>"
  :license "AGPL3"
  :depends-on (#+sbcl #:sb-introspect #:qlot
	       #:alexandria #:anaphora #:cl-fad #:closer-mop
	       #:cl-who #:cl-css #:parenscript
	       #:house #:fact-base)
  :components ((:module
                src :components
                ((:file "package")
                 (:file "model")
                 (:file "util")
                 (:file "publish-update")

                 (:module
                  ui :components
                  ((:module
                    http-api :components
                    ((:file "system")
                     (:file "notebook")
                     (:file "cell")))
                   (:module
                    http-front-end :components
                    ((:file "macros")
                     (:file "css")
                     (:file "core")

                     (:file "base") (:file "templates") (:file "api")
                     (:file "notebook-selector")
                     (:file "pareditesque")))))

                 (:file "evaluators")
                 (:file "exporters")


                 (:file "main")))))
