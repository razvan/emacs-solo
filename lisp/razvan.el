;;; package -- Disable TABs
(add-hook 'prog-mode-hook #'emacs-solo/prefer-spaces)
(add-hook 'text-mode-hook #'emacs-solo/prefer-spaces)
(setq-default indent-tabs-mode nil)

;; Ensure this keybinding works without having to cal magit-status manually once.
(use-package magit
  :ensure t
  :bind ("C-x g" . magit-status))

;;; Place cursor at the end of the scratch buffer at startup
(add-hook 'emacs-startup-hook
          (lambda ()
            (with-current-buffer "*scratch*"
              (goto-char (point-max)))))
(provide 'razvan)
;;; razvan.el ends here
