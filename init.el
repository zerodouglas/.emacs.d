(require 'package)

(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)

(package-initialize)
(setq package-native-compile t)
(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))

(setq use-package-always-ensure t)

(setq custom-file (expand-file-name "custom.el" user-emacs-directory))

(use-package no-littering
  :ensure t
  :init
  (setq auto-save-file-name-transforms
    `((".*" ,(no-littering-expand-var-file-name "auto-save/") t)))
  (setq no-littering-etc-directory
    (expand-file-name "config/" user-emacs-directory))
  (setq no-littering-var-directory
    (expand-file-name "data/" user-emacs-directory))
  (setq custom-file (expand-file-name "custom.el" user-emacs-directory))
  (unless (recentf-mode))
  (add-to-list 'recentf-exclude no-littering-var-directory)
  (add-to-list 'recentf-exclude no-littering-etc-directory))

(defun zerodouglas/comment-paragraph ()
  (interactive)
  (save-excursion
    (mark-paragraph)
    (comment-or-uncomment-region (region-beginning) (region-end))))

(global-set-key (kbd "C-c c") 'zerodouglas/comment-paragraph)

(defun eglot-format-buffer-on-save ()
  (add-hook 'before-save-hook #'eglot-format-buffer -10 t))
(add-hook 'go-mode-hook #'eglot-format-buffer-on-save)

(global-set-key (kbd "<f2>") 'kmacro-start-macro)
(global-set-key (kbd "<f3>") 'kmacro-end-macro)
(global-set-key (kbd "<f4>") 'call-last-kbd-macro)

(use-package emacs
  :custom
  (delete-selection-mode t)
  (show-paren-mode 1))

(use-package which-key
  :init
  (which-key-mode))

(use-package envrc
  :config
  :hook (prog-mode . envrc-global-mode))

(cl-defmacro def-repeat-map (name &key keys exit-with)
  (declare (indent 0))
  (let ((def-repeat-map-result nil))
    (when exit-with
      (push `(define-key ,name ,(kbd exit-with) #'keyboard-quit)
        def-repeat-map-result))
    (dolist (key (map-pairs keys))
      (push `(define-key ,name ,(car key) ,(cdr key))
        def-repeat-map-result)
      (push `(put ,(cdr key) 'repeat-map ',name)
        def-repeat-map-result))
    `(progn
       (defvar ,name (make-sparse-keymap))
       ,@def-repeat-map-result)))

(use-package repeat
  :ensure nil
  :init (repeat-mode 1)
  :config
  (def-repeat-map puni-expand-repeat-map
		  :keys ("." #'puni-expand-region))
  (def-repeat-map forward-word-repeat-map
		  :keys ("f" #'forward-word
			 "b" #'backward-word)
		  :exit-with "RET"))

(setq-default
 fill-column 80
 mark-ring-max 6
 global-mark-ring-max 6
 left-margin-width 1
 sentence-end-double-space nil
 kill-whole-line t)

(use-package elm-mode
  :config
  (setq elm-mode-hook '(elm-indent-simple-mode)))

(use-package go-mode)

(use-package haskell-mode
  :defer t
  :commands (haskell-mode)
  :init
  (defun ebn/haskell-mode-setup ()
    (interactive)
    (setq-local eldoc-documentation-function #'haskell-doc-current-info
        tab-stop-list '(2)
        indent-line-function #'indent-relative
        tab-width 2)
    (interactive-haskell-mode)
    (haskell-indentation-mode)
    (electric-pair-mode))
  (add-hook 'haskell-mode-hook #'ebn/haskell-mode-setup)

  :custom
  (haskell-process-type 'cabal-repl)
  (haskell-process-load-or-reload-prompt nil)
  (haskell-process-auto-import-loaded-modules t)
  (haskell-process-log t)
  (haskell-interactive-popup-errors nil)
  (haskell-font-lock-symbols t)

  :config
  (defun haskell-mode-after-save-handler ()
    (let ((inhibit-message t))
      (eglot-format-buffer))))

(use-package eglot
  :ensure t
  :hook
  (haskell-mode . eglot-ensure)
  (go-mode . eglot-ensure)
  (elm-mode . eglot-ensure)
  :custom
  (eglot-autoshutdown t)
  (eglot-autoreconnect nil)
  (eglot-confirm-server-initiated-edits nil)
  (eldoc-idle-delay 1)
  (eldoc-echo-area-display-truncation-message nil)
  (eldoc-echo-area-use-multiline-p 2))

(use-package corfu
  :custom
  (corfu-auto-delay 0.2)
  (corfu-cycle t)
  (corfu-auto t)
  (corfu-commit-predicate nil)
  (corfu-quit-at-boundary t)
  (corfu-quit-no-match t)
  (corfu-echo-documentation nil)
  :config
  (global-corfu-mode))

(use-package vertico
  :init
  (defvar last-file-name-handler-alist nil)
  (vertico-mode))

(use-package puni
  :ensure t
  :init
  (puni-global-mode)
  (electric-pair-mode)
  :bind
  ("C-." . puni-expand-region))

(use-package nix-mode
  :defer t
  :mode ("\\.nix\\'" . nix-mode))

(use-package doom-themes
  :config
  (load-theme 'doom-wilmersdorf t))

(use-package vertico
  :ensure
  :init
  (vertico-mode))

(use-package orderless
  :commands (orderless)
  :custom (completion-styles '(orderless flex)))

(use-package consult
  :ensure t
  :init
  (setq consult-preview-key nil)
  (recentf-mode)
  :bind
  (:map global-map
    ("C-c r" . consult-recent-file)
    ("C-c f" . consult-ripgrep)
    ("C-c l" . consult-line)
    ("C-c i" . consult-imenu)
    ("C-x b" . consult-buffer)
    ("C-c x" . consult-complex-command))
  (:map comint-mode-map
    ("C-c C-l" . consult-history)))

(defun zerodouglas/kill-current-buffer ()
  "Kill current buffer."
  (interactive)
  (kill-buffer (current-buffer)))

(defun zerodouglas/dired-up-directory ()
  "Up directory - killing current buffer."
  (interactive)
  (let ((cb (current-buffer)))
    (progn (dired-up-directory)
       (kill-buffer cb))))

(defun zerodouglas/copy-dwim ()
  "Run the command `kill-ring-save' on the current region
or the current line if there is no active region."
  (interactive)
  (if (region-active-p)
      (kill-ring-save nil nil t)
    (kill-ring-save (point-at-bol) (point-at-eol))))

(put 'narrow-to-region 'disabled nil)

(global-set-key (kbd "C-x k") 'zerodouglas/kill-current-buffer)
(global-set-key (kbd "M-w") 'zerodouglas/copy-dwim)

(use-package dired
  :ensure nil
  :config
  (setq dired-recursive-copies t
	dired-recursive-deletes t
	dired-dwim-target t
	delete-by-moving-to-trash t)
  :bind* (:map dired-mode-map
	       ("-" . zerodouglas/dired-up-directory)))
