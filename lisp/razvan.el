;;; package -- Personal tweaks
(add-hook 'prog-mode-hook #'emacs-solo/prefer-spaces)
(add-hook 'text-mode-hook #'emacs-solo/prefer-spaces)
(setq-default indent-tabs-mode nil)

;; Ensure this keybinding works without having to cal magit-status manually once.
(use-package magit
  :ensure t
  :bind ("C-x g" . magit-status))

;; Manage GitHub issues and pull requests
;; Requires an access token in ~/.authinfo.gpg in the form of:
;;   machine api.github.com login YOUR_USERNAME^forge password YOUR_TOKEN
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
(use-package forge
  :ensure t
  :after magit)
;; Where the token used by forge is stored
(setq auth-sources '("~/.authinfo"))

;;; Place cursor at the end of the scratch buffer at startup
(add-hook 'emacs-startup-hook
          (lambda ()
            (with-current-buffer "*scratch*"
              (goto-char (point-max)))))

;;; Open buffer in browser (for files hosted on GitHub)
(use-package git-link
  :ensure t
  :bind ("C-c g o" . git-link)
  :custom
  ;; Default to the main/master branch link instead of current commit hash (optional)
  ;; (git-link-use-commit nil)
  ;; Automatically open the URL in your web browser after generating link
  (git-link-open-in-browser t))

(provide 'razvan)
;;; razvan.el ends here
