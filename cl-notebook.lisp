(in-package #:cl-notebook)

; Basic server-side definitions and handlers
;;;;; Read/eval-related
(defmethod front-end-eval (cell-language cell-type (contents string))
  "A cell that fits no other description returns a"
  (list
   (alist 
    :stdout "" :warnings nil ; Without these, :json encodes this as an array rather than an object
    :values (list (alist :type 'error :value 
			 (alist 'condition-type "UNKNOWN-LANGUAGE:TYPE-COMBINATION" 
				'cell-language cell-language
				'cell-type cell-type))))))

(defmethod front-end-eval ((cell-language (eql :common-lisp)) cell-type (contents string))
  "A Common-Lisp:Code cell is just evaluated, capturing all warnings, stdout emissions and errors."
  (capturing-eval contents))

(defmethod front-end-eval ((cell-language (eql :common-lisp)) (cell-type (eql :markup)) (contents string))
  "A Common-Lisp:Markup cell is evaluated as a :cl-who tree"
  (list
   (alist :stdout "" :warnings nil ; Without these, :json encodes this as an array rather than an object
	  :values
	  (handler-case
	      (list
	       (alist 
		:type "string"
		:value (eval 
			`(with-html-output-to-string (s) 
			   ,@(read-all contents)))))
	    (error (e)
	      (list (alist :type 'error :value (front-end-error nil e))))))))

(defmethod eval-notebook-code ((book fact-base))
  (let ((all-ids (reverse (caddar (lookup book :b :cell-order)))))
    (loop for (id b c) in (lookup book :b :cell :c nil) do (pushnew id all-ids))
    (let ((ids (reverse all-ids)))
      (loop for cell-id in ids
	 when (and (lookup book :a cell-id :b :cell-language :c :common-lisp)
		   (lookup book :a cell-id :b :cell-type :c :code))
	 do (let ((stale? (first (lookup book :a cell-id :b :stale :c t)))
		  (res-fact (first (lookup book :a cell-id :b :result))))
	      (let ((res 
		     (handler-case
			 (bt:with-timeout (.1)
			   (front-end-eval 
			    :common-lisp :code 
			    (caddar (lookup book :a cell-id :b :contents))))
		       (sb-ext:timeout () :timed-out))))
		(unless (eq :timed-out res)
		  (when stale? (delete! book stale?))
		  (unless (equalp (third res-fact) res)
		    (when res-fact (delete! book res-fact))
		    (insert! book (list cell-id :result res)))))))
      (write! book))))

(defmethod empty-expression? ((contents string))
  (when (cl-ppcre:scan "^[ \n\t\r]*$" contents) t))

(defmethod eval-cell ((book fact-base) cell-id (contents string) val-fact cell-language cell-type)
  (unless (empty-expression? contents)
    (when (and (bt:threadp *front-end-eval-thread*)
	       (bt:thread-alive-p *front-end-eval-thread*))
      (bt:destroy-thread *front-end-eval-thread*))
    (publish! :cl-notebook-updates (update :book (notebook-id book) :cell cell-id :action 'starting-eval))
    (setf *front-end-eval-thread*
	  (bt:make-thread
	   (lambda ()
	     (in-package :cl-notebook)
	     (let ((res (front-end-eval cell-language cell-type contents)))
	       (when (and val-fact res)
		 (delete! book val-fact)
		 (insert! book (list cell-id :result res))
		 (delete! book (list cell-id :stale t))
		 (write! book))
	       (publish! :cl-notebook-updates 
			 (update :book (notebook-id book) 
				 :cell cell-id 
				 :action 'finished-eval 
				 :contents contents 
				 :result res))))))))

;;;;; Model-related
(defvar *notebooks* (make-hash-table :test 'equal))
(defvar *front-end-eval-thread* nil)

(defmethod new-cell! ((book fact-base) &key (cell-language :common-lisp) (cell-type :code))
  (multi-insert! book `((:cell nil) (:cell-type ,cell-type) (:cell-language ,cell-language) (:contents "") (:result ""))))

(defmethod remove-notebook! ((book fact-base))
  (remhash (notebook-id book) *notebooks*))

(defmethod register-notebook! ((book fact-base))
  (setf (gethash (notebook-id book) *notebooks*) book))

(defmethod get-notebook ((name string))
  (gethash name *notebooks*))

(defmethod notebook-id ((book fact-base))
  (file-namestring (file-name book)))

(defmethod notebook-name ((book fact-base))
  (caddar (lookup book :b :notebook-name)))

(defmethod rename-notebook! ((book fact-base) (new-name string))
  (let ((name-fact (first (lookup book :b :notebook-name))))
    (delete! book name-fact)
    (insert-new! book :notebook-name new-name)
    book))

(defun new-notebook! (name)
  (let ((book (make-fact-base :indices *default-indices* :file-name (merge-pathnames (fact-base::temp-file-name) *books*))))
    (insert-new! book :notebook-name name)
    (register-notebook! book)
    book))

(defmethod make-unique-name-in ((dir pathname) (base-name string))
  (assert (cl-fad:directory-pathname-p dir))
  (let ((name (merge-pathnames base-name dir)))
    (if (cl-fad:file-exists-p name)
	(loop for i from 0
	   for name = (merge-pathnames (format nil "~a-~a" base-name i) dir)
	   unless (cl-fad:file-exists-p name) return name)
	name)))

(defmethod kill! ((book fact-base))
  (let ((trash-name (make-unique-name-in *trash*  (file-namestring (file-name book)))))
    (rename-file (file-name book) trash-name)
    (remove-notebook! book)))

(defmethod load-notebook! ((name pathname))
  (let ((book (load! name :indices *default-indices* :in-memory? t)))
    (eval-notebook-code book)
    (register-notebook! book)))

;;;;; HTTP Handlers
(define-json-handler (cl-notebook/system/kill-thread) ()
  (when (and (bt:threadp *front-end-eval-thread*)
	     (bt:thread-alive-p *front-end-eval-thread*))
    (bt:destroy-thread *front-end-eval-thread*))
  (publish! :cl-notebook-updates (update :action 'killed-eval))
  :ok)

(define-json-handler (cl-notebook/notebook/rewind) ((book :notebook) (index :integer))
  (hash :facts (rewind-to book index) :history-size (total-entries book) :history-position index :id (notebook-id book)))

(define-json-handler (cl-notebook/notebook/current) ((book :notebook))
  (hash :facts (current book) :history-size (total-entries book) :id (notebook-id book)))

(define-json-handler (cl-notebook/notebook/fork-at) ((book :notebook) (index :integer))
  (let ((new (load! 
	      (fork-at book index :file-name (merge-pathnames (fact-base::temp-file-name) *books*))
	      :indices *default-indices* :in-memory? t))
	(new-name (format nil "Fork of ~a" (notebook-name book))))
    (delete! new (first (lookup new :b :notebook-name)))
    (insert-new! new :notebook-name new-name)
    (register-notebook! new)
    (publish! :cl-notebook-updates (update :action 'new-book :book (notebook-id new) :book-name new-name))
    (hash :facts (current new) :history-size (total-entries new) :id (notebook-id new))))

(define-json-handler (cl-notebook/notebook/new) ()
  (let* ((name (format nil "book-~a" (hash-table-count *notebooks*)))
	 (book (new-notebook! name)))
    (write! book)
    (publish! :cl-notebook-updates (update :action 'new-book (notebook-id book) :book-name name))
    (hash :facts (current book) :history-size (total-entries book))))

(define-json-handler (cl-notebook/notebook/kill) ((book :notebook))
  (kill! book)
  (publish! :cl-notebook-updates (update :book (notebook-id book) :action 'kill-book))
  :ok)

(define-json-handler (cl-notebook/notebook/rename) ((book :notebook) (new-name :string))
  (let* ((old-name (notebook-name book))
	 (book (rename-notebook! book new-name)))
    (write! book)
    (publish! :cl-notebook-updates (update :book old-name :action 'rename-book :new-name new-name)))
  :ok)

(define-json-handler (cl-notebook/notebook/eval-to-cell) ((book :notebook) (cell-id :integer) (contents :string))
  (let ((cont-fact (first (lookup book :a cell-id :b :contents)))
	(val-fact (first (lookup book :a cell-id :b :result)))
	(cell-lang (caddar (lookup book :a cell-id :b :cell-language)))
	(cell-type (caddar (lookup book :a cell-id :b :cell-type))))
    (delete! book cont-fact)
    (insert! book (list cell-id :contents contents))
    (publish! :cl-notebook-updates (update :book (notebook-id book) :cell cell-id :action 'content-changed :contents contents))
    (eval-cell book cell-id contents val-fact cell-lang cell-type))
  :ok)

(define-json-handler (cl-notebook/notebook/change-cell-contents) ((book :notebook) (cell-id :integer) (contents :string))
  (let ((cont-fact (first (lookup book :a cell-id :b :contents))))
    (unless (string= contents (third cont-fact))
      (delete! book cont-fact)
      (insert! book (list cell-id :stale t))
      (insert! book (list cell-id :contents contents))
      (publish! :cl-notebook-updates (update :book (notebook-id book) :cell cell-id :action 'content-changed :contents contents))))
  :ok)

(define-json-handler (cl-notebook/notebook/change-cell-language) ((book :notebook) (cell-id :integer) (new-language :keyword))
  (let ((cont-fact (first (lookup book :a cell-id :b :contents)))
	(val-fact (first (lookup book :a cell-id :b :result)))	
	(cell-type (caddar (lookup book :a cell-id :b :cell-type)))
	(lang-fact (first (lookup book :a cell-id :b :cell-language))))
    (unless (eq (third lang-fact) new-language)
      (delete! book lang-fact)
      (insert! book (list cell-id :cell-type new-language))
      (publish! 
       :cl-notebook-updates 
       (update :book (notebook-id book) :cell cell-id :action 'change-cell-language :new-language new-language))
      (eval-cell book cell-id (third cont-fact) val-fact new-language cell-type)))
  :ok)

(define-json-handler (cl-notebook/notebook/change-cell-type) ((book :notebook) (cell-id :integer) (new-type :keyword))
  (let ((cont-fact (first (lookup book :a cell-id :b :contents)))
	(val-fact (first (lookup book :a cell-id :b :result)))
	(cell-lang (caddar (lookup book :a cell-id :b :cell-language)))
	(tp-fact (first (lookup book :a cell-id :b :cell-type))))
    (unless (eq (third tp-fact) new-type)
      (delete! book tp-fact)
      (insert! book (list cell-id :cell-type new-type))
      (publish! 
       :cl-notebook-updates 
       (update :book (notebook-id book) :cell cell-id :action 'change-cell-type :new-type new-type))
      (eval-cell book cell-id (third cont-fact) val-fact cell-lang new-type)))
  :ok)

(define-json-handler (cl-notebook/notebook/new-cell) ((book :notebook) (cell-language :keyword) (cell-type :keyword))
  (let ((cell-id (new-cell! book :cell-type cell-type :cell-language cell-language)))
    (write! book)
    (publish! 
     :cl-notebook-updates 
     (update :book (notebook-id book) :action 'new-cell :cell-id cell-id 
	     :cell-type cell-type :cell-language cell-language)))
  :ok)

(define-json-handler (cl-notebook/notebook/reorder-cells) ((book :notebook) (cell-order :json))
  (awhen (lookup book :b :cell-order)
    (delete! book (car it)))
  (insert-new! book :cell-order cell-order)
  (write! book)
  (publish! :cl-notebook-updates (update :book (notebook-id book) :action 'reorder-cells :new-order cell-order))
  :ok)

(define-json-handler (cl-notebook/notebook/kill-cell) ((book :notebook) (cell-id :integer))
  (loop for f in (lookup book :a cell-id) do (delete! book f))
  (write! book)
  (publish! :cl-notebook-updates (update :book (notebook-id book) :cell cell-id :action 'kill-cell))
  :ok)

(define-json-handler (cl-notebook/notebook/change-cell-noise) ((book :notebook) (cell-id :integer) (new-noise :keyword))
  (awhen (first (lookup book :a cell-id :b :noise))
    (delete! book it))
  (unless (eq new-noise :normal)
    (insert! book (list cell-id :noise new-noise)))
  (publish! :cl-notebook-updates (update :book (notebook-id book) :cell cell-id :action 'change-cell-noise :new-noise new-noise))
  :ok)

(define-handler (cl-notebook/source :close-socket? nil) ()
  (subscribe! :cl-notebook-updates sock))
