;;; org-relativity.el --- relative timestamps for Org

;;; Commentary:
;;
;;; Code:
(require 'org)
(require 'org-element)

;;@TODO: compute end time range and add to timestamps
;;e.g. 00:00-0:30 with effort = 0:30

(defun org-relativity-effort-to-minutes (effort)
  "Convert an EFFORT string to minutes.
String is expected to be of form HH:MM."
  (if effort
      (let ((units (mapcar #'string-to-number (split-string effort ":"))))
        (+ (* (car units) 60) (cadr units)))
    0))

;;@BUG: what happens when range spans over a day?
;;do we want multiple timestamps? e.g.
;;<t1>--<t2>?
(defun org-relativity-ranged-timesstamp (timestamp effort)
  "Calculate a time range of form HH:MM-HH:MM.
Argument TIMESTAMP tbd.
Argument EFFORT tbd.")

(defun org-relativity-entry-p ()
  "Return t if entry at point has a non-nil relativity property, nil otherwise."
  (when-let ((relativity (org-entry-get (point) "relativity")))
    (and (read relativity) t)))

(defun org-relativity-root ()
  "Goto root of outline.")

(defun org-relativity-schedule-tree (&rest _args)
  "Do something."
  (interactive)
  (let ((org-log-reschedule nil)
        scheduled
        effort)
    (save-excursion
      (while (org-up-heading-safe))
      (when (org-relativity-entry-p)
        (save-restriction
          (org-narrow-to-subtree)
          (org-map-tree (lambda ()
                          (let ((p (point)))
                            (when scheduled
                              (org-schedule nil scheduled)
                              (save-excursion
                                (save-restriction
                                  (org-narrow-to-subtree)
                                  (when (re-search-forward org-scheduled-time-regexp nil t)
                                    (org-timestamp-change (org-relativity-effort-to-minutes effort) 'minute)))))
                            (setq scheduled (org-element-interpret-data
                                             (org-timestamp-from-time
                                              (org-get-scheduled-time p) t))
                                  effort (org-entry-get p "EFFORT"))))))))))

(progn
  (advice-remove #'org-timestamp-up      #'org-relativity-numeric-move-advice)
  (advice-remove #'org-timestamp-down    #'org-relativity-numeric-move-advice)
  (advice-remove #'org-move-subtree-up   #'org-relativity-numeric-move-advice)
  (advice-remove #'org-move-subtree-down #'org-relativity-numeric-move-advice)
  (advice-remove #'org-set-effort        #'org-relativity-schedule-tree))

;;@RESEARCH: why can't we pass numeric arg with simple :after advice?
;;@INCOMPLETE: what other commands should we advise?
(progn
  (advice-add #'org-timestamp-up      :around #'org-relativity-numeric-move-advice)
  (advice-add #'org-timestamp-down    :around #'org-relativity-numeric-move-advice)
  (advice-add #'org-move-subtree-up   :around #'org-relativity-numeric-move-advice)
  (advice-add #'org-move-subtree-down :around #'org-relativity-numeric-move-advice)
  (advice-add #'org-set-effort        :after #'org-relativity-schedule-tree))

(defun org-relativity-numeric-move-advice (advised &optional arg)
  ".
Argument ADVISED tbd.
Optional argument ARG tbd."
  (interactive "p")
  (funcall advised arg)
  (org-relativity-schedule-tree))

(provide 'org-relativity)

;;; org-relativity.el ends here
