(in-package :claxiom)

(define-handler (js/api.js :content-type "application/javascript") ()
  (ps (defun kill-thread ()
	(post/json "/claxiom/system/kill-thread" (create)))

      (defun arg-hint (symbol x y &key current-arg)
	(post/json "/claxiom/system/arg-hint" (create :name symbol :package :claxiom)
		   (lambda (res)
		     (unless (and (@ res error) (= (@ res error) 'function-not-found))
		       (dom-append
			(by-selector "body")
			(who-ps-html
			 (:div :class "notebook-arg-hint cm-s-default"
			       :style (+ "left:" x "px; top: " y "px")
			       "(" (:span :class "name" symbol)
			       (join (loop for arg in (@ res args)
					collect (cond
						  ((and (string? arg) (= (@ arg 0) "&"))
						   (who-ps-html (:span :class "modifier cm-variable-2" arg)))
						  ((string? arg)
						   (who-ps-html (:span :class "arg" arg)))
						  (t
						   (who-ps-html (:span :class "compound-arg"
								       "(" (join
									    (loop for a in arg
									       if (null a)
									       collect (who-ps-html (:span :class "arg" "NIL"))
									       else collect (who-ps-html (:span :class "arg" a)))) ")")))))) ")")))))))

      (defun rewind-book (index)
	(post/json "/claxiom/notebook/rewind" (create :book (notebook-id *notebook*) :index index)
		   #'notebook!))

      (defvar debounced-rewind (debounce #'rewind-book 10))

      (defun fork-book (callback)
	(post/json "/claxiom/notebook/fork-at" (create :book (notebook-id *notebook*) :index (@ (by-selector "#book-history-slider") value))
		   callback))

      (defun export-book (format)
        (when format
          (post/json "/claxiom/notebook/export"
                     (create :book (notebook-id *notebook*) :format format)
                     (lambda (data)
                       (console.log data)
                       (save-file
                        (@ data :name)
                        (@ data :contents)
                        (+ (@ data :mimetype) ";charset=utf-8"))))
          (setf (@ (by-selector "#book-exporters") value) "")))

      (defun notebook/current (name)
	(post/json "/claxiom/notebook/current" (create :book name)
		   #'notebook!
		   (lambda (res)
		     (dom-set
		      (by-selector "#notebook")
		      (who-ps-html (:h2 "Notebook '" name "' not found..."))))))

      (defun new-book (path)
        (post/json "/claxiom/notebook/new" (create :path path) #'notebook!))

      (defun load-book (path)
        (post/json "/claxiom/notebook/load" (create :path path) #'notebook!))

      (defun rename-book (new-name)
	(post/fork "/claxiom/notebook/rename" (create :book (notebook-id *notebook*) :new-name new-name)))

      (defun repackage-book (new-package)
	(post/fork "/claxiom/notebook/repackage" (create :book (notebook-id *notebook*) :new-package new-package)))

      (defun notebook/eval-to-cell (cell-id contents)
	(post/fork "/claxiom/notebook/eval-to-cell" (create :book (notebook-id *notebook*) :cell-id cell-id :contents contents)))

      (defun new-cell (&optional (cell-language :common-lisp) (cell-type :code))
	(post/fork "/claxiom/notebook/new-cell" (create :book (notebook-id *notebook*) :cell-type cell-type :cell-language cell-language)))

      (defun kill-cell (cell-id)
	(post/fork "/claxiom/notebook/kill-cell" (create :book (notebook-id *notebook*) :cell-id cell-id)))

      (defun change-cell-contents (cell-id contents)
	(post/fork "/claxiom/notebook/change-cell-contents" (create :book (notebook-id *notebook*) :cell-id cell-id :contents contents)))

      (defun change-cell-type (cell-id new-type)
	(post/fork "/claxiom/notebook/change-cell-type" (create :book (notebook-id *notebook*) :cell-id cell-id :new-type new-type)))

      (defun change-cell-language (cell-id new-language)
	(post/fork "/claxiom/notebook/change-cell-language" (create :book (notebook-id *notebook*) :cell-id cell-id :new-language new-language)))

      (defun change-cell-noise (cell-id new-noise)
	(post/fork "/claxiom/notebook/change-cell-noise" (create :book (notebook-id *notebook*) :cell-id cell-id :new-noise new-noise)))

      (defun reorder-cells (ev)
	(prevent ev)
	(let ((ord (loop for elem in (by-selector-all ".cell")
		       collect (parse-int (chain elem (get-attribute :cell-id))))))
          (notebook-cell-ordering! *notebook* ord)
	  (post "/claxiom/notebook/reorder-cells"
		(create :book (notebook-id *notebook*)
			:cell-order (obj->string ord)))))

      (defun system/macroexpand-1 (expression callback)
	(post "/claxiom/system/macroexpand-1"
	      (create :expression expression)
	      callback))
      (defun system/macroexpand (expression callback)
	(post "/claxiom/system/macroexpand"
	      (create :expression expression)
	      callback))))
