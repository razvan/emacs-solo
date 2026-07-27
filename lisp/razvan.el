;;; package -- Disable TABs
(add-hook 'prog-mode-hook #'emacs-solo/prefer-spaces)
(add-hook 'text-mode-hook #'emacs-solo/prefer-spaces)
(setq-default indent-tabs-mode nil)

(provide 'razvan)
;;; razvan.el ends here
