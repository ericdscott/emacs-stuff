
;; This is a simple utility for togglind buffers 'on/off-deck' and being able
;; to invoke 'on-deck-switch' and be prompted for the set of *on-deck* buffers.

(defun on-deck-prompt-for-buffer (buffer-names)
  (let ((candidates (exclude-current-buffer-name buffer-names)))
    (if (= (length candidates) 1) candidates (completing-read "on deck: " candidates))))

(define-minor-mode on-deck-mode
  "Puts buffers on or off deck"
  :keymap (let ((map (make-sparse-keymap)))
            (define-key map (kbd "C-c C-d t") 'on-deck-toggle)
            (define-key map (kbd "C-c C-d s") 'on-deck-switch)
            map)
  :group 'mode-line
  (on-deck-update-mode-line)
  )

(setq *on-deck* (if (boundp '*on-deck*) *on-deck* nil))

(defun on-deck-clean-up ()
  (setq *on-deck* (cl-remove-if
                   #'(lambda (b) (not (buffer-name b)))
                   *on-deck*))
  *on-deck*)

(defun on-deck-clear-deck ()
  (interactive)
  (save-excursion
    (dolist (b *on-deck*)
      (switch-to-buffer b)
      (on-deck-off-deck))))

(defun on-deck-buffer-is-on-deck (b)
  (seq-find (lambda (e) (eq b e)) (on-deck-clean-up)))

(setq on-deck-mode-line-status "")

(defun on-deck-update-mode-line ()
  (setq on-deck-mode-line-status
        (if (on-deck-buffer-is-on-deck (current-buffer))
            " On Deck"
          " Off Deck"))
  (setq mode-line-format
        (cl-remove-duplicates
         (append mode-line-format (list 'on-deck-mode-line-status))))
  (force-mode-line-update))

(defun on-deck-on-deck ()
  (interactive)
  (let ((b (current-buffer)))
    (if (not (seq-find (lambda (e) (eq b e)) (on-deck-clean-up)))
        (let ()
          (setq *on-deck* (append *on-deck* (list b)))
          (on-deck-update-mode-line)))))

(defun on-deck-off-deck ()
  (interactive)
  (let ((b (current-buffer)))
    (if (seq-find (lambda (e) (eq b e)) (on-deck-clean-up))
        (let ()
          (setq  *on-deck* (seq-remove (lambda (e) (eq e b)) *on-deck*))
          (on-deck-update-mode-line)))))

(defun on-deck-toggle ()
  (interactive)
  (if (on-deck-buffer-is-on-deck (current-buffer))
      (on-deck-off-deck)
    (on-deck-on-deck))
  (message on-deck-mode-line-status))

(defun on-deck-switch (to-buffer)
  (interactive (list (on-deck-prompt-for-buffer
                      (mapcar #'buffer-name (on-deck-clean-up)))))
  (switch-to-buffer (if (listp to-buffer)
                        (car to-buffer)
                      to-buffer)))
