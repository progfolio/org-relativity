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

(defun org-relativity-schedule-tree (&rest _args)
  "Do something."
  (interactive)
  (let ((org-log-reschedule nil)
        scheduled
        effort)
    (save-excursion
      (save-restriction
        (while (org-up-heading-safe))
        (org-narrow-to-subtree)
        (org-map-tree (lambda ()
                        (let ((p (point)))
                          (when scheduled
                            (org-schedule nil scheduled)
                            (save-excursion
                              (save-restriction
                                (beginning-of-line)
                                (org-narrow-to-subtree)
                                (when (re-search-forward org-scheduled-time-regexp nil t)
                                  (org-timestamp-change (org-relativity-effort-to-minutes effort) 'minute)))))
                          (setq scheduled (org-element-interpret-data
                                           (org-timestamp-from-time
                                            (org-get-scheduled-time p) t))
                                effort (org-entry-get p "EFFORT")))))))))
(progn
  (advice-remove #'org-timestamp-up   #'org-relativity-advice)
  (advice-remove #'org-timestamp-down #'org-relativity-advice)
  (advice-remove #'org-set-effort     #'org-relativity-schedule-tree))

;;@RESEARCH: why can't we pass numeric arg with simple :after advice?
(progn
  (advice-add #'org-timestamp-up   :around #'org-relativity-timestamp-advice)
  (advice-add #'org-timestamp-down :around #'org-relativity-timestamp-advice)
  (advice-add #'org-set-effort     :after #'org-relativity-schedule-tree))

(defun org-relativity-timestamp-advice (advised &optional arg)
  "."
  (funcall advised arg)
  (org-relativity-schedule-tree))




;;advise org-timestamp-up/down?
;;advise org-clock-modify-effort-estimate
;;advise org-insert-property
;;(org-timestamp-change)

(provide 'org-relativity)

;;; org-relativity.el ends here
