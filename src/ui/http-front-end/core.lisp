(in-package :claxiom)

(define-handler (/) ()
  (with-html-output-to-string (s nil :prologue t :indent t)
    (:html
     (:head
      (:title "claxiom")

      (:link :rel "stylesheet" :href "/css/notebook.css")
      (:link :rel "stylesheet" :href "/static/css/genericons.css")
      (:link :rel "stylesheet" :href "/static/css/codemirror.css")
      (:link :rel "stylesheet" :href "/static/css/dialog.css")
      (:link :rel "stylesheet" :href "/static/css/show-hint.css")

      (:script
       :type "text/javascript"
       (str
        (format
         nil "var CLAXIOM = ~a"
         (json:encode-json-to-string
          (hash
           :formats
           (hash :eval (front-end-eval-formats)
                 :export (export-book-formats)))))))

      (:script :type "text/javascript" :src "/js/base.js")

      (:script :type "text/javascript" :src "/static/js/Blob.js")
      (:script :type "text/javascript" :src "/static/js/FileSaver.js")

      (:script :type "text/javascript" :src "/js/templates.js")
      (:script :type "text/javascript" :src "/js/api.js")
      (:script :type "text/javascript" :src "/js/core.js")
      (:script :type "text/javascript" :src "/js/pareditesque.js")
      (:script :type "text/javascript" :src "/js/notebook-selector.js")
      (:script :type "text/javascript" :src "/static/js/native-sortable.js")

      (:script :type "text/javascript" :src "/static/js/codemirror.js")

      (:script :type "text/javascript" :src "/static/js/modes/commonlisp.js")
      (:script :type "text/javascript" :src "/static/js/addons/comment.js")
      (:script :type "text/javascript" :src "/static/js/addons/closebrackets.js")
      (:script :type "text/javascript" :src "/static/js/addons/matchbrackets.js")
      (:script :type "text/javascript" :src "/static/js/addons/search.js")
      (:script :type "text/javascript" :src "/static/js/addons/searchcursor.js")
      (:script :type "text/javascript" :src "/static/js/addons/match-highlighter.js")
      (:script :type "text/javascript" :src "/static/js/addons/active-line.js")
      (:script :type "text/javascript" :src "/static/js/addons/mark-selection.js")
      (:script :type "text/javascript" :src "/static/js/addons/show-hint.js")
      (:script :type "text/javascript" :src "/static/js/addons/anyword-hint.js")
      (:script :type "text/javascript" :src "/static/js/addons/dialog.js")
      (:script :type "text/javascript" :src "/static/js/addons/runmode/runmode.js"))

     (:body
      (:span :id "claxiom-front-end-addons"
             (:link :rel "stylesheet" :href "/css/notebook-addons.css"))
      (:div :id "macro-expansion" (:textarea :language "commonlisp"))
      (:div :id "notebook")
      (:div :class "main-controls"
            (:div :id "notebook-selector")
	    (:input :id "book-history-slider" :onchange "rewindBook(this.value)" :oninput "debouncedRewind(this.value)" :type "range" :min 0 :max 500 :value 500)
	    (:button :onclick "newCell()" "> New Cell")
            (:button :onclick "toggleOpenBookMenu()" "> Open Book")
	    (:select :id "book-exporters"
		     :onchange "exportBook(this.value)"
                     :onselect "exportBook(this.value)"
		     (:option :value "" "Export as...")
                     (loop for format in (export-book-formats)
                             do (htm (:option :value format (str format)))))
            (:div :class "thread-controls"
                  (:span :class "notice" "Processing")
                  (:img :src "/static/img/dots.png")
                  (:button :onclick "killThread()" :class "right" "! Abort")))))))

(define-handler (js/core.js :content-type "application/javascript") ()
  (ps
    ;; claxiom specific utility
    (defun by-cell-id (cell-id &rest children)
      (by-selector
       (+ "#cell-" cell-id
	  (if (> (length children) 0) " " "")
	  (join children " "))))

    (defun elem->cell-id (elem)
      (parse-int
       (chain elem (get-attribute "id")
	      (match (-reg-exp "cell-([1234567890]+)"))
	      1)))

    (defun elem-to-cell (elem)
      (aref *notebook* :objects (elem->cell-id elem)))

    (defun clear-selection ()
      (let ((sel (chain window (get-selection))))
	(if (@ sel empty)
	    ;; chrome
	    (chain sel (empty))
	    ;; firefox
	    (chain sel (remove-all-ranges)))))

    (defun select-contents (ev elem)
      (unless (@ ev shift-key)
	(clear-selection))
      (let ((r (new (-range))))
	(chain r (select-node-contents elem))
	(chain window (get-selection) (add-range r))))

    (defun in-present? ()
      (let ((slider (by-selector "#book-history-slider")))
	(= (@ slider value) (chain slider (get-attribute :max)))))

    (defun post/fork (uri args on-success on-fail)
      (if (in-present?)
	  (post/json uri args on-success on-fail)
	  (fork-book (lambda (res)
		       (surgical! res)
		       (setf document.title (+ (@ res book-name) " - claxiom"))
		       (setf (@ args :book) (@ res id))
		       (dom-replace (by-selector ".book-title") (notebook-title-template (@ res book-name)))
		       (post/json uri args on-success on-fail)))))

    ;; claxiom specific events
    (defun reload-addon-resources! (resource-type resource-name)
      (console.log "RELOADING" resource-type resource-name "(TODO - be surgical about this)")
      (dom-set
       (by-selector "#claxiom-front-end-addons")
       (who-ps-html
        (:link :rel "stylesheet" :href (+ "/css/notebook-addons.css?now=" (now!))))))

    (defun hash-updated ()
      (let ((book-name (@ (get-page-hash) :book)))
	(when book-name
	  (notebook/current book-name))
        (dom-set (by-selector "#notebook-selector") "")))

    (defun esc-pressed ()
      (clear-selection)
      (hide-title-input)
      (hide-macro-expansion!)
      (hide-open-book-menu!)
      (map (lambda (cell)
             (with-slots (id cell-type) cell
               (when (= :markup cell-type)
                 (hide-editor id))))
           (notebook-cells *notebook*)))

    ;; claxiom specific DOM manipulation
    (defun display-book (book-name)
      (when book-name
	(set-page-hash (create :book book-name))
	(hash-updated)))

    (defun hide-open-book-menu! ()
      (dom-set (by-selector "#notebook-selector") ""))

    (defun toggle-open-book-menu ()
      (let ((el (by-selector "#notebook-selector")))
        (if (dom-empty? el)
            (notebook-selector! "#notebook-selector")
            (dom-set el ""))))

    (defun dom-replace-cell-value! (cell)
      (when (@ cell result)
	(let ((res (@ cell result result)))
	  (dom-set (by-cell-id (@ cell :id) ".cell-value")
                   (cell-value-template cell)))))

    (defun dom-replace-cell (cell)
      (dom-replace (by-cell-id (@ cell id)) (cell-template cell))
      (setup-cell-mirror! cell))

    ;; CodeMirror and utilities
    (defun register-helpers (type object)
      (map
       (lambda (fn name)
	 (chain -code-mirror
		(register-helper type name fn)))
       object))

    (defun register-commands (object)
      (map
       (lambda (fn name)
	 (setf (aref -code-mirror :commands name) fn))
       object))

    (defun show-editor (cell-id)
      (show! (by-cell-id cell-id ".CodeMirror"))
      (chain (cell-mirror cell-id) (focus)))

    (defun hide-editor (cell-id)
      (hide! (by-cell-id cell-id ".CodeMirror")))

    (defun cell-mirror (cell-id)
      (@ (notebook-cell *notebook* cell-id) editor))

    (defun cell-editor-contents (cell-id)
      (chain (cell-mirror cell-id) (get-value)))

    (defun eval-ps-cell! (cell)
      (with-captured-log log-output
        (chain
         cell result
         (push
          (try
           (let* ((res (window.eval (@ cell result 0 values 0 value)))
                  (tp (typeof res)))
             (create
              :stdout (join log-output #\newline) :warnings nil
              :values (list (create :type tp :value (+ "" res)))))
           (:catch (err)
             (create
              :stdout (join log-output #\newline) :warnings nil
              :values (list (create :type "error" :value (list err.message))))))))))

    (defun mirror! (text-area &key (extra-keys (create)) (line-wrapping? t))
      (let ((options
	     (create
	      "async" t
	      "lineNumbers" t
	      "matchBrackets" t
	      "autoCloseBrackets" t
	      "lineWrapping" line-wrapping?
	      "viewportMargin" -infinity
	      "smartIndent" t
	      "extraKeys" (extend
			   (create "Ctrl-Space" 'autocomplete

				   "Ctrl-Right" (lambda (mirror) (go-sexp :right mirror))
				   "Ctrl-Left" (lambda (mirror) (go-sexp :left mirror))
				   "Shift-Ctrl-Right" (lambda (mirror) (select-sexp :right mirror))
				   "Shift-Ctrl-Left" (lambda (mirror) (select-sexp :left mirror))

				   "Ctrl-Down" (lambda (mirror) (go-block :down mirror))
				   "Shift-Ctrl-Down" (lambda (mirror) (select-block :down mirror))
				   "Ctrl-Up" (lambda (mirror) (go-block :up mirror))
				   "Shift-Ctrl-Up" (lambda (mirror) (select-block :up mirror))

				   "Ctrl-Alt-K" (lambda (mirror) (kill-sexp :right mirror))
				   "Shift-Ctrl-Alt-K" (lambda (mirror) (kill-sexp :left mirror))
				   "Tab" 'indent-auto

				   "Ctrl-;" (lambda (mirror) (toggle-comment-region mirror)))
			   extra-keys))))
	(chain -code-mirror (from-text-area text-area options))))

    (defun setup-cell-mirror! (cell)
      (let* ((cell-id (@ cell id))
	     (mirror (mirror! (by-cell-id cell-id ".cell-contents")
			      :extra-keys (create
					   "Ctrl-Enter"
					   (lambda (mirror)
					     (let ((contents (cell-editor-contents cell-id)))
					       (notebook/eval-to-cell cell-id contents)))

					   "Ctrl-]" (lambda (mirror) (go-cell :down cell-id))
					   "Ctrl-[" (lambda (mirror) (go-cell :up cell-id))
					   "Shift-Ctrl-]" (lambda (mirror) (transpose-cell! :down cell-id))
					   "Shift-Ctrl-[" (lambda (mirror) (transpose-cell! :up cell-id))
					   "Shift-Ctrl-E" (lambda (mirror)
							    (show-macro-expansion!)
							    (chain *macro-expansion-mirror* (focus)))
					   "Ctrl-E" (lambda (mirror)
						      (system/macroexpand-1
						       (sexp-at-point :right mirror)
						       (lambda (res)
							 (show-macro-expansion!)
							 (chain *macro-expansion-mirror*
								(set-value res)))))
					   "Ctrl-Space" (lambda (mirror)
							  (console.log "TOKEN: " (token-type-at-cursor :right mirror)))
					   "Ctrl-Delete" (lambda (mirror)
							   (kill-cell cell-id)
							   (let ((prev (get-cell-before *notebook* cell-id)))
							     (when prev
							       (show-editor (@ prev id)))))))))
	(setf (@ cell editor) mirror)
	(chain mirror (on 'cursor-activity
			  (lambda (mirror)
			    (unless (chain mirror (something-selected))
			      (chain mirror (exec-command 'show-arg-hint))))))
        (chain mirror (on 'change
                          (lambda (mirror)
                            (let ((elem (by-cell-id (@ cell id))))
                              (if (= (chain mirror (get-value)) (@ cell contents))
                                  (chain elem class-list (remove "stale"))
                                  (chain elem class-list (add "stale")))))))
	(unless (= (@ cell type) "markup")
	  (chain mirror (on 'change
			    (lambda (mirror change)
			      (when (or (= "+input" (@ change origin)) (= "+delete" (@ change origin)))
				(chain -code-mirror commands
				       (autocomplete
					mirror (@ -code-mirror hint ajax)
					(create :async t "completeSingle" false))))))))
	mirror))

    ;; Notebook-related
    (defvar *notebook*)

    (defun notebook-condense (notebook)
      (let ((res (create)))
	(loop for (id prop val) in notebook
	   unless (aref res id) do (setf (aref res id) (create :id id))
	   do (if (null val)
		  (setf (aref res id :type) prop)
		  (setf (aref res id prop) val)))
	res))

    (defun notebook-name (notebook) (@ notebook name))
    (defun notebook-package (notebook) (@ notebook package))
    (defun notebook-id (notebook) (@ notebook id))
    (defun notebook-name! (notebook new-name) (setf (@ notebook name) new-name))
    (defun notebook-package! (notebook new-package) (setf (@ notebook package) new-package))

    (defun notebook-facts (notebook) (@ notebook facts))
    (defun notebook-objects (notebook) (@ notebook objects))

    (defun notebook-cell-ordering! (notebook new-order)
      (let ((id (or (loop for (a b c) in (notebook-facts notebook)
                       when (= b 'cell-order) do (return a))
                    -1)))
        (setf
         (@ notebook facts)
         (chain
          (list (list id 'cell-order new-order))
          (concat
           (filter
            (lambda (fact) (not (= (@ fact 1) 'cell-order)))
            (notebook-facts notebook))))
         (aref (@ notebook objects) id) (create id id cell-order new-order))))

    (defun notebook-cell-ordering (notebook)
      (let ((ord (loop for (a b c) in (notebook-facts notebook)
		    when (= b 'cell-order) do (return c)))
	    (all-cell-ids
	     (loop for (a b c) in (notebook-facts notebook)
		when (and (= b 'cell) (null c)) collect a)))
	(chain all-cell-ids (reverse))
	(if ord
	    (append-new ord all-cell-ids)
	    all-cell-ids)))

    (defun notebook-cells (notebook)
      (let ((obj (notebook-objects notebook))
	    (ord (notebook-cell-ordering notebook)))
	(loop for id in ord for res = (aref obj id)
	   when res collect res)))

    (defun notebook-cell (notebook id)
      (aref notebook :objects id))

    (defun unfocus-cells ()
      (loop for c in (by-selector-all ".cell.focused")
         do (chain c class-list (remove "focused"))))

    (defun focus-cell (cell-id)
      (let ((cell (by-cell-id cell-id)))
        (unless (chain cell class-list (contains "focused"))
          (unfocus-cells)
          (chain (by-cell-id cell-id) class-list (add "focused")))))

    (defun get-cell-after (notebook cell-id)
      (loop for (a b) on (notebook-cells notebook)
	 if (and a (= (@ a id) cell-id))
	 return b))

    (defun get-cell-before (notebook cell-id)
      (loop for (a b) on (notebook-cells notebook)
	 if (and b (= (@ b id) cell-id))
	 return a))

    (defun setup-package-mirror! ()
      (mirror!
       (by-selector ".book-package textarea")
       :extra-keys
       (create "Ctrl-]"     (lambda (mirror)
			      (let ((next (by-selector ".cells .cell")))
				(when next
				  (hide-title-input)
				  (scroll-to-elem next)
				  (show-editor (elem->cell-id next)))))
	       "Ctrl-Enter" (lambda (mirror)
			      (repackage-book (chain mirror (get-value))))))
      (hide! (by-selector ".book-package")))

    (defun setup-macro-expansion-mirror! ()
      (setf *macro-expansion-mirror*
	    (mirror!
	     (by-selector "#macro-expansion textarea")
	     :line-wrapping? nil
	     :extra-keys
	     (create "Ctrl-E" (lambda (mirror)
				(system/macroexpand-1
				 (sexp-at-point :right mirror)
				 (lambda (res)
				   (chain
				    mirror
				    (operation
				     (lambda ()
				       (let ((start (get-cur :right mirror)))
					 (replace-sexp-at-point :right mirror res)
					 (chain mirror (set-selection start (get-cur :right mirror)))
					 (chain mirror (exec-command 'indent-auto))
					 (chain mirror (set-cursor start)))))))))))))

    (defun surgical! (raw)
      (let* ((slider (by-selector "#book-history-slider"))
	     (count (@ raw history-size))
	     (pos (or (@ raw history-position) count))
	     (id (@ raw id)))
	(chain slider (set-attribute :max count))
	(setf (@ *notebook* id) id
	      (@ slider value) pos)
	(hide! (by-selector ".book-title input"))
	(setup-package-mirror!)
	(set-page-hash (create :book id))))

    (defvar *notebook-loaded-hook*
      (lambda () (console.log "FINISHED LOADING BOOK")))

    (defun book-ready (callback)
      (setf *notebook-loaded-hook* callback)
      nil)

    (defun notebook! (raw)
      (clear-all-delays!)
      (let* ((fs (@ raw facts)))
	(setf *notebook*
	      (create :facts fs :objects (notebook-condense fs)
		      :history-size (@ raw history-size)
		      :id (@ raw :id)
		      :name (loop for (a b c) in fs
			       when (equal b "notebookName")
			       do (return c))
		      :package (loop for (a b c) in fs
				  when (equal b "notebookPackage")
				  do (return c))))
        (map (lambda (cell)
               (when (= :parenscript (@ cell cell-type))
                 (eval-ps-cell! cell)))
             (notebook-cells *notebook*))
	(dom-set
	 (by-selector "#notebook")
	 (notebook-template *notebook*))
	(surgical! raw)
	(setf document.title (+ (notebook-name *notebook*) " - claxiom"))
	(nativesortable (by-selector "ul.cells"))
	(map (lambda (cell)
	       (with-slots (id cell-type) cell
		 (setup-cell-mirror! cell)
		 (when (= :markup cell-type)
		   (hide! (by-cell-id id ".CodeMirror")))))
	     (notebook-cells *notebook*))
        (funcall *notebook-loaded-hook*)))

    (defun relevant-event? (ev)
      (and (in-present?) (equal (notebook-id *notebook*) (@ ev book))))

    (defun notebook-events ()
      (event-source
       "/claxiom/source"
       (create
	'new-cell
	(lambda (res)
	  (when (relevant-event? res)
	    (let ((id (@ res 'cell-id))
		  (cell (create 'type "cell" 'contents "" 'result ""
				'cell-type (@ res cell-type)
				'cell-language (@ res cell-language)
				'id (@ res 'cell-id))))
	      (setf (aref (notebook-objects *notebook*) id) cell)
	      (chain (notebook-facts *notebook*) (unshift (list id 'cell nil)))
	      (dom-append (by-selector ".cells")
			  (cell-template cell))
	      (setup-cell-mirror! cell)
	      (scroll-to-elem (by-cell-id id))
	      (show-editor id))))
	'change-cell-type
	(lambda (res)
	  (when (relevant-event? res)
	    (let ((cell (notebook-cell *notebook* (@ res cell))))
	      (setf (@ cell cell-type) (@ res new-type))
	      (dom-replace-cell cell))))
	'change-cell-language
	(lambda (res)
	  (when (relevant-event? res)
	    (let ((cell (notebook-cell *notebook* (@ res cell))))
	      (setf (@ cell cell-language) (@ res new-language))
	      (dom-replace-cell cell))))
	'change-cell-noise
	(lambda (res)
	  (when (relevant-event? res)
	    (let ((cell (notebook-cell *notebook* (@ res cell))))
	      (setf (@ cell noise) (@ res new-noise))
	      (dom-replace-cell-value! cell))))
	'starting-eval
	(lambda (res) (show-thread-controls!))
	'killed-eval
	(lambda (res) (hide-thread-controls!))
	'finished-eval
	(lambda (res)
	  (hide-thread-controls!)
	  (when (relevant-event? res)
	    (let ((cell (notebook-cell *notebook* (@ res cell))))
	      (setf (@ cell contents) (@ res contents)
		    (@ cell result) (@ res result))
	      (delete (@ cell stale))
	      (chain (by-cell-id (@ res cell)) class-list (remove "stale"))
              (when (= :parenscript (@ cell cell-type))
                (eval-ps-cell! cell))
	      (dom-replace-cell-value! cell))))
	'finished-package-eval
	(lambda (res)
	  (hide-thread-controls!)
	  (let ((id (@ res book))
		(new-package (@ res contents))
		(err (@ res result)))
	    (when (relevant-event? res)
	      (dom-replace (by-selector ".book-package") (notebook-package-template new-package err))
	      (notebook-package! *notebook* new-package)
	      (setup-package-mirror!)
	      (if err
		  (show-title-input)
		  (hide-title-input)))))
        'addon-updated
        (lambda (res)
          (reload-addon-resources! (@ res addon-type) (@ res addon-name)))

	'loading-package
	(lambda (res) (show-thread-controls! (+ "Loading package '" (@ res package) "'")))
	'finished-loading-package
	(lambda (res) (hide-thread-controls!))
	'package-load-failed
	(lambda (res) (hide-thread-controls!))

	'content-changed
	(lambda (res)
	  (when (relevant-event? res)
	    (let* ((cell (notebook-cell *notebook* (@ res cell)))
		   (mirror (cell-mirror (@ res cell)))
		   (cursor (chain mirror (get-cursor))))
	      (setf (@ cell contents) (@ res contents)
		    (@ cell stale) t)
	      (chain (by-cell-id (@ res cell)) class-list (add "stale"))
	      (chain mirror (set-value (@ res contents)))
	      (chain mirror (set-cursor cursor)))))
	'kill-cell
	(lambda (res)
	  (when (relevant-event? res)
	    (delete (aref *notebook* 'objects (@ res cell)))
	    (chain (by-cell-id (@ res cell)) (remove))))

	'reorder-cells
	(lambda (res)
	  (when (relevant-event? res)
            (unless (equal? (@ res new-order) (notebook-cell-ordering *notebook*))
              (let* ((ord (@ res new-order))
                     (cs (loop for n in ord
                            collect (by-cell-id n)))
                     (elem (by-selector "#notebook .cells")))
                (dom-empty! elem)
                (loop for c in cs do (chain elem (append-child c)))
                (notebook-cell-ordering! *notebook* ord)))))

	'new-book
	(lambda (res)
	  (let ((id (@ res book)))
	    (console.log "NEW BOOK CREATED" book)))

	'rename-book
	(lambda (res)
	  (let ((id (@ res book))
		(new-name (@ res new-name)))
	    (when (relevant-event? res)
	      (dom-replace (by-selector ".book-title") (notebook-title-template new-name))
	      (notebook-name! *notebook* new-name)
	      (hide-title-input)))))))

    (defvar *warning-filter*
      (lambda (w)
	(or (chain (@ w condition-type) (starts-with "REDEFINITION"))
	    (chain (@ w condition-type) (starts-with "IMPLICIT-GENERIC-"))
	    (and (@ w error-message)
		 (or  (chain (@ w error-message) (starts-with "undefined "))
		      (chain (@ w error-message) (ends-with "never used.")))))))

    (dom-ready
     (lambda ()
       ;;; Setting up some custom CodeMirror code ;;;;;;;;;;;;;;;;;;;;
       (register-helpers
	"hint"
	(create :ajax
		(lambda (mirror callback options)
		  (let* ((cur (chain mirror (get-cursor)))
			 (tok (chain mirror (get-token-at cur))))
		    (when (> (length (@ tok string)) 2)
		      (get "/claxiom/system/complete" (create :partial (@ tok string) :package :claxiom)
			   (lambda (res)
			     (callback
			      (create :list (or (string->obj res) (new (-array)))
				      :from (chain -code-mirror (-pos (@ cur line) (@ tok start)))
				      :to (chain -code-mirror (-pos (@ cur line) (@ tok end))))))))))
		:auto
		(lambda (mirror options)
		  (chain -code-mirror commands
			 (autocomplete mirror (@ -code-mirror hint ajax) (create :async t))))))

       (register-commands
	(create show-arg-hint
		(debounce
		 (lambda (mirror)
		   ($aif (by-selector-all ".notebook-arg-hint")
			 (map (lambda (elem) (chain elem (remove))) it))
		   (labels ((find-first (ctx)
			      (cond ((null ctx) nil)
				    ((or (= "arglist" (@ ctx node_type))
					 (and (@ ctx prev)
					      (@ ctx prev node_type)
					      (= "arglist" (@ ctx prev node_type)))) nil)
				    ((= "(" (@ ctx opening)) (@ ctx first))
				    (t (find-first (@ ctx prev))))))
		     (let* ((coords (chain mirror (cursor-coords)))
			    (cur (chain mirror (get-cursor)))
			    (tok (chain mirror (get-token-at cur))))
		       ($aif (and tok (find-first (@ tok state ctx)))
			     (arg-hint it (+ 1 (@ coords right)) (@ coords bottom))))))
		 100)))
       ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
       (notebook-events)
       (hide-thread-controls!)
       (hide-macro-expansion!)
       (chain
        (by-selector "body")
        (add-event-listener
         :keydown (key-listener
                   <esc> (esc-pressed)
                   "O" (when ctrl?
                         (toggle-open-book-menu)
                         (chain event (prevent-default)))
		   "?" (when ctrl?
			 (console.log "TODO" :show-help-here))
		   <space> (when ctrl?
			     (new-cell)
			     (chain event (prevent-default))))))

       (unless (get-page-hash)
         (get/json
          "/claxiom/loaded-books" (create)
          (lambda (dat)
            (set-page-hash (create :book (@ dat 0 path))))))
       (setup-macro-expansion-mirror!)
       (setf (@ window onhashchange) #'hash-updated)
       (hash-updated)))))
