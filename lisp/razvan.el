;;; package -- Personal tweaks -*- lexical-binding: t; -*-
;;; Commentary:
;;  My cusotmizations in after solo.
;;
;;; Code:
(add-hook 'prog-mode-hook #'emacs-solo/prefer-spaces)
(add-hook 'text-mode-hook #'emacs-solo/prefer-spaces)
(setq-default indent-tabs-mode nil)
;; Automatically save/restore desktop on exit
(desktop-save-mode 1)

;; Ensure this keybinding works without having to cal magit-status manually once.
(use-package magit
  :ensure t
  :bind ("C-x g" . magit-status))

;; ;; Manage GitHub issues and pull requests
;; ;; Requires an access token in ~/.authinfo.gpg in the form of:
;; ;;   machine api.github.com login YOUR_USERNAME^forge password YOUR_TOKEN
;; (add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
;; (use-package forge
;;   :ensure t
;;   :after magit)
;; ;; Where the token used by forge is stored
;; (setq auth-sources '("~/.authinfo"))

;;; Place cursor at the end of the scratch buffer at startup
(add-hook 'emacs-startup-hook
          (lambda ()
            (with-current-buffer "*scratch*"
              (goto-char (point-max)))))

;; ;;; Open buffer in browser (for files hosted on GitHub)
;; (use-package git-link
;;   :ensure t
;;   :bind ("C-c g o" . git-link)
;;   :custom
;;   ;; Default to the main/master branch link instead of current commit hash (optional)
;;   ;; (git-link-use-commit nil)
;;   ;; Automatically open the URL in your web browser after generating link
;;   (git-link-open-in-browser t))

;;; Tell project to ignore Cargo.toml as project marker and only look for .git.
;;; This avoids the Cargo workspace problem where visiting a file in a crate
;;; restricts project commands to that crate instead of the entire workspace.
(use-package project
  :ensure nil ; Built-in
  :config
  ;; Always use the root VCS (.git) directory as the project root
  (setq project-vc-extra-root-markers '(".git")))

;; Toggle a symbol outline frame
(use-package imenu-list
  :ensure t
  :bind ("C-c l l" . imenu-list-smart-toggle))

;; (use-package blamer
;;   :ensure t
;;   :bind (("s-i" . blamer-show-commit-info)
;;          ("C-c g b" . blamer-show-posframe-commit-info))
;;   :defer 20
;;   :custom
;;   (blamer-idle-time 0.3)
;;   (blamer-min-offset 70)
;;   :custom-face
;;   (blamer-face ((t :foreground "#7a88cf"
;;                     :background nil
;;                     :height 110
;;                     :italic t)))
;;   :config
;;   (global-blamer-mode 1))

;; WORKAROUND: C-SPC would silently fail to make a selection, typically right
;; after switching windows with C-x o.  `string-pixel-width' measures a string
;; by inserting it into the reusable " *work*" buffer; it guards its own
;; `insert' against clobbering `deactivate-mark' (subr-x.el, "Avoid
;; deactivating the region as side effect") but `work-buffer--release' calls
;; `erase-buffer' unguarded, so releasing the work buffer sets
;; `deactivate-mark' and the command loop then kills the region.
;;
;; Both `mode--line-format-right-align' and `tab-bar-format-align-right'
;; measure that way, and `line-move-visual' (i.e. plain C-n) re-evaluates the
;; mode line when the window geometry cache is stale -- which is exactly what
;; C-x o invalidates.  Hence: mark, move, region gone.
;;
;; `inhibit-modification-hooks' makes `prepare_to_modify_buffer_1' return
;; before it touches `deactivate-mark', which is harmless for a scratch work
;; buffer.  Drop this once Emacs guards `work-buffer--release' itself.
(defun razvan/pixel-width-preserve-region (orig &rest args)
  "Call ORIG with ARGS without letting work-buffer edits clobber the region."
  (let ((inhibit-modification-hooks t))
    (apply orig args)))

(advice-add 'string-pixel-width :around #'razvan/pixel-width-preserve-region)
(advice-add 'truncate-string-pixelwise :around #'razvan/pixel-width-preserve-region)

(provide 'razvan)
;;; razvan.el ends here
