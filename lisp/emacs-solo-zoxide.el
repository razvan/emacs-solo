;;; emacs-solo-zoxide.el --- Zoxide-like directory jumping for Eshell  -*- lexical-binding: t; -*-
;;
;; Author: Rahul Martim Juliato
;; URL: https://github.com/LionyxML/emacs-solo
;; Package-Requires: ((emacs "31.1"))
;; Keywords: eshell, convenience
;; SPDX-License-Identifier: GPL-3.0-or-later

;;; Commentary:
;;
;; Records every directory visited in Eshell, ranked by visit count.
;;
;;   z, z -         go home
;;   z --           back to the previous dir (like eshell's `cd -')
;;   z foo          jump to the most visited dir whose name matches foo
;;   z proj foo     terms match in order, the last one in the dir name
;;   z-clean        wipe the cache
;;
;; `cd' falls back to `z' matching when its arg is not a directory
;; (see `emacs-solo-zoxide-replace-cd').

;;; Code:

(use-package emacs-solo-zoxide
  :ensure nil
  :no-require t
  :defer t
  :init
  (defvar emacs-solo-zoxide-file
    (if (fboundp 'emacs-solo--cache-path)
        (emacs-solo--cache-path 'emacs-solo-zoxide-file)
      (expand-file-name "cache/zoxide.eld" user-emacs-directory))
    "File where visited Eshell directories are stored.")

  (defvar emacs-solo-zoxide--dirs nil
    "Alist of (DIR . COUNT).")

  (declare-function emacs-solo-zoxide--load nil)
  (defun emacs-solo-zoxide--load ()
    (when (and (null emacs-solo-zoxide--dirs)
               (file-exists-p emacs-solo-zoxide-file))
      (with-temp-buffer
        (insert-file-contents emacs-solo-zoxide-file)
        (setq emacs-solo-zoxide--dirs (ignore-errors (read (current-buffer)))))))

  (declare-function emacs-solo-zoxide--save nil)
  (defun emacs-solo-zoxide--save ()
    (make-directory (file-name-directory emacs-solo-zoxide-file) t)
    (with-temp-file emacs-solo-zoxide-file
      (prin1 emacs-solo-zoxide--dirs (current-buffer))))

  (declare-function emacs-solo-zoxide--record nil)
  (defun emacs-solo-zoxide--record ()
    "Bump the visit count of `default-directory'."
    (let ((dir (abbreviate-file-name (expand-file-name default-directory))))
      (unless (or (file-remote-p dir) (equal dir "~/"))
        (emacs-solo-zoxide--load)
        (let ((cell (assoc dir emacs-solo-zoxide--dirs)))
          (if cell
              (setcdr cell (1+ (cdr cell)))
            (push (cons dir 1) emacs-solo-zoxide--dirs)))
        (emacs-solo-zoxide--save))))

  (defvar emacs-solo-zoxide-replace-cd t
    "When non-nil, `cd' falls back to zoxide matching.")

  (declare-function emacs-solo-zoxide--terms nil)
  (defun emacs-solo-zoxide--terms (args)
    (mapcar (lambda (a) (format "%s" a)) (flatten-tree args)))

  (declare-function emacs-solo-zoxide--find nil)
  (defun emacs-solo-zoxide--find (terms)
    "Return the most visited directory matching TERMS, or nil."
    (emacs-solo-zoxide--load)
    (let* ((case-fold-search t)
           (here (abbreviate-file-name (expand-file-name default-directory)))
           (re (concat (mapconcat (lambda (s) (concat (regexp-quote s) ".*"))
                                  (butlast terms) "")
                       (regexp-quote (car (last terms)))
                       "[^/]*/\\'")))
      (car (seq-find (lambda (cell)
                       (and (not (equal (car cell) here))
                            (string-match-p re (car cell))
                            (file-directory-p (car cell))))
                     (sort emacs-solo-zoxide--dirs :key #'cdr :reverse t)))))

  (declare-function eshell/cd nil)
  (defun eshell/z (&rest args)
    "Jump to the most visited directory matching ARGS.
No ARGS or `-' goes home, `--' goes to the previous directory and an
existing directory is entered directly."
    (let ((terms (emacs-solo-zoxide--terms args)))
      (cond
       ((or (null terms) (equal terms '("-"))) (eshell/cd))
       ((equal terms '("--")) (eshell/cd "-"))
       ((and (null (cdr terms)) (file-directory-p (car terms)))
        (eshell/cd (car terms)))
       (t
        (let ((hit (emacs-solo-zoxide--find terms)))
          (if hit
              (eshell/cd hit)
            (error "No match for %s" (string-join terms " "))))))))

  (declare-function emacs-solo-zoxide--cd nil)
  (defun emacs-solo-zoxide--cd (orig &rest args)
    "Make `cd' jump like `z' when ARGS is not a directory."
    (let ((terms (emacs-solo-zoxide--terms args)))
      (if (or (not emacs-solo-zoxide-replace-cd)
              (null terms)
              (string-match-p "\\`[-=]" (car terms))
              (and (null (cdr terms)) (file-directory-p (car terms))))
          (apply orig args)
        (let ((hit (emacs-solo-zoxide--find terms)))
          (if hit (funcall orig hit) (apply orig args))))))

  (with-eval-after-load 'em-dirs
    (advice-add 'eshell/cd :around #'emacs-solo-zoxide--cd))

  (declare-function eshell-printn nil)
  (defun eshell/z-clean ()
    "Wipe the zoxide directory cache."
    (setq emacs-solo-zoxide--dirs nil)
    (when (file-exists-p emacs-solo-zoxide-file)
      (delete-file emacs-solo-zoxide-file))
    (eshell-printn "z: cache cleared"))

  (add-hook 'eshell-directory-change-hook #'emacs-solo-zoxide--record))

(provide 'emacs-solo-zoxide)
;;; emacs-solo-zoxide.el ends here
