;; ln -s .../.emacs ~/.emacs

;; Highlight matching parentheses
(show-paren-mode 1)

;; Typing text replaces marked regions
(delete-selection-mode 1)

(setq
 ;; Always display error backtraces
 debug-on-error t

 ;; Disable prompt to saving abbreviations
 save-abbrevs nil

 ;; Disable start screen 
 inhibit-startup-screen t

 ;; Disable backup files
 make-backup-files nil
 auto-save-default nil
 backup-inhibited t

 ;; Disable lockfiles
 create-lockfiles nil

 ;; Always follow symbolic links to version controlled files
 vc-follow-symlinks t

 ;; Mac ls does not implement --dired
 dired-use-ls-dired nil

 ;; Minibuffer line and column
 line-number-mode t
 column-number-mode t

 ;; Smoother mouse scrolling
 mouse-wheel-scroll-amount '(0.01)

 ;; Default to Unix LF line endings
 buffer-file-coding-system 'utf-8-unix
 ;; Soft tabs
 indent-tabs-mode nil
 ;; Width: 2 spaces
 sws-tab-width 2
 ;; And shell
 sh-basic-offset 2
 sh-indentation 2
 ;; And JavaScript
 js-indent-level 2)

;; Disable paging, esp. for psql
(setenv "PAGER" (executable-find "cat"))

;; Disable ncurses menubar
(menu-bar-mode -1)

;; Force save.
(defadvice save-buffer (before save-buffer-always activate)
  (set-buffer-modified-p t))

;; Alt+F4 quits.
(global-set-key (kbd "M-<f4>") 'save-buffers-kill-terminal)

(if window-system
    ;; CUA tools in GUI mode
    (progn

      ;; Hide GUI toolbar
      (tool-bar-mode -1)

      ;; Font: Monaco
      ;; http://usystem.googlecode.com/files/MONACO.TTF
      (condition-case nil
          (progn
            ;; Font size: ~10pt
            (set-face-attribute 'default nil :height
                                (pcase system-type
                                  (`darwin 120)
                                  (`gnu/linux 90)))
            (set-frame-font "Monaco"))
        (error (warn "Monaco font is not installed"))))

  (progn
    ;; CUA OS copypasta in ncurses mode
    (pcase system-type
      (`darwin (setq interprogram-cut-function
                     (lambda (text &optional push)
                       (let* ((process-connection-type nil)
                              (pbproxy (start-process "pbcopy" "pbcopy" "/usr/bin/pbcopy")))
                         (process-send-string pbproxy text)
                         (process-send-eof pbproxy))))
               (setq interprogram-paste-function (lambda () (shell-command-to-string "pbpaste"))))
      (`gnu/linux (progn
                    (setq x-select-enable-clipboard t)
                    (defun xsel-cut-function (text &optional push)
                      (with-temp-buffer
                        (insert text)
                        (call-process-region (point-min) (point-max) "xsel" nil 0 nil "--clipboard" "--input")))
                    (defun xsel-paste-function()
                      (let ((xsel-output (shell-command-to-string "xsel --clipboard --output")))
                        (unless (string= (car kill-ring) xsel-output)
                          xsel-output )))
                    (setq interprogram-cut-function 'xsel-cut-function)
                    (setq interprogram-paste-function 'xsel-paste-function))))

    ;;
    ;; Enable OS mouse clicking and scrolling
    ;;
    ;; Note for Mac OS X: Requires SIMBL and MouseTerm
    ;;
    ;; http://www.culater.net/software/SIMBL/SIMBL.php
    ;; https://bitheap.org/mouseterm/
    ;;
    (xterm-mouse-mode 1)
    (global-set-key [mouse-4]
                    (lambda ()
                      (interactive)
                      (scroll-down 1)))
    (global-set-key [mouse-5]
                    (lambda ()
                      (interactive)
                      (scroll-up 1)))))

;; Compile .emacs on save
(add-hook 'after-save-hook
          (lambda ()
            ;; (interactive)
            ;; (require 'bytecomp)
            (let ((dotemacs (expand-file-name "~/.emacs")))
              (if (string= (buffer-file-name) (file-chase-links dotemacs))
                  (byte-compile-file dotemacs)))))

;; I say, soft tabs, width 2 spaces!
(setq-default indent-tabs-mode nil
              tab-width 2)

(add-to-list 'auto-mode-alist '("\\.mf$" . makefile-mode))
(add-to-list 'auto-mode-alist '("pylintrc" . conf-mode))
(add-to-list 'auto-mode-alist '("pep8" . conf-mode))
(add-to-list 'auto-mode-alist '("\\.ackrc$" . conf-mode))
(add-to-list 'auto-mode-alist '("Cask$" . lisp-mode))

(require 'cask "~/.cask/cask.el")
(cask-initialize)

(require 'use-package)

;; Fast line numbers
(use-package nlinum
  :init
  (progn
    ;; Line number gutter in ncurses mode
    (unless window-system
      (setq nlinum-format "%d ")))
  :idle
  (global-nlinum-mode))

;; Column 80 marker
(use-package column-enforce-mode
  :diminish column-enforce-mode
  :init
  (progn
    (set-face-background 'column-enforce-face "#660000")
    (add-hook 'prog-mode-hook 'column-enforce-mode)))

;; Lua indentation
(add-hook 'lua-mode-hook
          (lambda ()
            (defvar lua-indent-level)
            (setq lua-indent-level tab-width)))
;; Tcl indentation
(add-hook 'tcl-mode-hook
          (lambda ()
            (defvar tcl-indent-level)
            (setq tcl-indent-level tab-width)))
;; CSS indentation
(add-hook 'css-mode-hook
          (lambda ()
            (defvar css-indent-offset)
            (setq css-indent-offset 2)))
;; Perl indentation
(fset 'perl-mode 'cperl-mode)
;; Python indentation
(add-hook 'python-mode-hook
          (lambda ()
            (defvar python-indent)
            (defvar python-indent-offset)
            (setq tab-width 2
                  python-indent 2
                  python-indent-offset 2)))
;; Rust indentation
(add-hook 'rust-mode-hook
          (lambda ()
            (defvar rust-indent-unit)
            (defvar rust-indent-offset)
            (setq rust-indent-unit tab-width
                  rust-indent-offset tab-width)))
;; Shell script indentation
(add-hook 'shell-mode-hook
          (lambda () (setq indent-tabs-mode nil)))
;; Go indentation
(add-hook 'go-mode-hook
          (lambda () (setq indent-tabs-mode nil)))
;; Haskell indentation
(add-hook 'haskell-mode-hook
          (lambda ()
            (turn-on-haskell-indentation)
            (setq tab-width tab-width)))
;; PostScript indentation
(add-hook 'ps-mode-hook
          (lambda ()
            (defvar ps-mode-tab)
            (setq ps-mode-tab tab-width)))
;; Objective C indentation
(add-hook 'objc-mode-hook
          (lambda ()
            (defvar indent-tabs-mode)
            (setq indent-tabs-mode nil)))
;; Mozart/Oz indentation
(add-hook 'oz-mode-hook
          (lambda ()
            (defvar oz-indent-chars)
            (setq oz-indent-chars tab-width)))

(defun hard-tabs ()
  (setq-default indent-tabs-mode t)
  (setq indent-tabs-mode t
        tab-width 2))

;; Makefile indentation
(add-hook 'makefile-mode-hook 'hard-tabs)
(add-hook 'makefile-gmake-mode-hook 'hard-tabs)
(add-hook 'makefile-bsdmake-mode-hook 'hard-tabs)

(defun i-said-soft-tabs ()
  (untabify (point-min) (point-max))
  (indent-region (point-min) (point-max)))

;; Find and Replace
(use-package findr
  :commands findr-query-replace)

;; Open project file by fuzzy name
(use-package fiplr
  :bind ("C-p" . fiplr-find-file)
  :config
  (progn
    (defvar fiplr-ignored-globs)
    (setq fiplr-ignored-globs
          '((directories (".git"
                          ".svn"
                          ".hg"
                          ".bzr"

                          ;; NPM
                          "node_modules"

                          ;; Maven
                          "target"
                          "resources"))
            (files       (".#*"
                          "*~"
                          "*.so"
                          "*.jpg"
                          "*.png"
                          "*.gif"
                          "*.pdf"
                          "*.gz"
                          "*.zip"))))))

;; C-x <direction> to switch windows
(use-package window-jump
  :bind (("C-x <up>" . window-jump-up)
         ("C-x <down>" . window-jump-down)
         ("C-x <left>" . window-jump-left)
         ("C-x <right>" . window-jump-right)))

;; Monokai
(use-package monokai-theme
  :idle
  (load-theme 'monokai t))

;;
;; CUA-like Undo (Control+Z, Control+R)
;;
(use-package undo-tree
  :bind (("C-z" . undo-tree-undo)
         ("C-r" . undo-tree-redo))
  :config
  (global-undo-tree-mode))

;; If mark exists, indent rigidly.
;; Otherwise, insert a hard or soft tab indentation.
(defun traditional-indent ()
  (interactive)
  (if mark-active
    (indent-rigidly (region-beginning) (region-end) tab-width)))
;; ;; Inverse.
;; (defun traditional-outdent ()
;;   (interactive)
;;   (if mark-active
;;     (indent-rigidly (region-beginning) (region-end) (* tab-width -1))
;;     (delete-backward-char tab-width)))

(use-package markdown-mode
  :mode "\\.md$"
  :init
  (progn
    ;; Use markdown-mode for *scratch*
    (setq initial-scratch-message nil
          initial-major-mode 'markdown-mode)

    ;; Block indent for Markdown
    (add-hook 'markdown-mode-hook
              (lambda ()
                (setq indent-tabs-mode nil
                      tab-width 4)
                (define-key markdown-mode-map (kbd "<tab>") 'traditional-indent)
                (define-key markdown-mode-map (kbd "<backtab>") 'traditional-outdent)))))

;; M-; toggles commenting for marked region or current line.
(use-package evil-nerd-commenter
  :bind ("M-;" . evilnc-comment-or-uncomment-lines))

;; Single dired buffer
(use-package dired-single
  :commands dired-single-buffer dired-single-buffer-mouse
  :init
  (add-hook 'dired-mode-hook
            (lambda ()
              ;; Enable all commands
              (setq disabled-command-function nil)

              (defvar dired-mode-map)
              (define-key dired-mode-map [return] 'dired-single-buffer)
              (define-key dired-mode-map [down-mouse-1] 'dired-single-buffer-mouse)
              (define-key dired-mode-map [^]
                (lambda ()
                  (interactive)
                  (dired-single-buffer "..")))

              ;; Auto-refresh dired on file change
              (auto-revert-mode)
              (setq-default auto-revert-interval 1)

              (use-package dired-details
                :init
                (progn
                  ;; Hide dired file permissions
                  (declare-function dired-details-install "dired-details.el" nil)
                  (dired-details-install)
                  (defvar dired-details-hidden-string)
                  (setq dired-details-hidden-string "")))

              (use-package dired+
                :init
                (progn
                  ;; Fix color theme
                  (setq-default dired-omit-files-p t)
                  (setq font-lock-maximum-decoration (quote ((dired-mode) (t . t))))
                  (defvar dired-omit-files)
                  (setq dired-omit-files (concat dired-omit-files "\\.")))))))

;;
;; Syntax highlighting
;;

;;
;; SQL
;;

(add-hook 'sql-mode-hook 'sqlup-mode)
(add-to-list 'auto-mode-alist
             '("\\.psql$" .
               (lambda ()
                 (sql-mode)
                 (sql-highlight-postgres-keywords))))

;;
;; Fix SQL indentation
;;

(defun get-previous-indentation ()
  "Get the column of the previous indented line"
  (interactive)
  (save-excursion
    (progn
      (move-beginning-of-line nil)
      (skip-chars-backward "\n \t")
      (back-to-indentation))
    (current-column)))

(defun get-current-indentation ()
  "Return column at current indentation"
  (interactive)
  (save-excursion
    (progn
      (back-to-indentation)
      (current-column))))

(defun point-at-current-indentation ()
  "Return point at current indentation"  
  (interactive)
  (save-excursion
    (progn
      (move-to-column (get-current-indentation))
      (point))))

(defun point-at-column-on-line (col)
  "Returns the point at `col` on the current line"
  (interactive)
  (save-excursion
    (progn
      (move-to-column col)
      (point))))

(defun ig-move-line-to-column (col)
  "Move the line to col; fill with all spaces if moveing forward"
  (interactive "p")
  (let ((point-at-cur-indent (point-at-current-indentation))
        (col-at-cur-indent (get-current-indentation)))
    (cond (
           (= col 0)
           ;; delete to beginning of line or do nothing
           (if (= col-at-cur-indent 0)
               nil
             (delete-region point-at-cur-indent (point-at-column-on-line 0))))
          (
           (< col col-at-cur-indent)
           ;; delete from our current point BACK to col
           (delete-region (point-at-column-on-line col) point-at-cur-indent))
          (
           (> col col-at-cur-indent)
           ;; delete all text from indent to beginning of line
           (progn
             (delete-region point-at-cur-indent (point-at-column-on-line 0))
             (move-beginning-of-line nil)
             ;; add spaces forward
             (insert (make-string col ?\s)))))))

(defun ig-indent-sql ()
  "Indent by `tab-width` at most 1 time greater than the previously indented
line otherwise go to the beginning of the line indent forward by `tab-width`"
  (let ((previous (get-previous-indentation))
        (current (get-current-indentation)))
    (cond ( ;; exactly at previous line's indentation
           (= previous current)
           (ig-move-line-to-column (+ current tab-width)))

          ( ;; current is greater than previous
           (> current previous)
           ;; exactly at one indentation forward from previous lines indent
           (if (= tab-width (- current previous))
               ;; move line to beginning
               (ig-move-line-to-column 0)
             ;; go back to previous indentation level
             (ig-move-line-to-column previous)))

          (t 
           (ig-move-line-to-column (+ current tab-width))))))

(add-hook 'sql-mode-hook
          (lambda ()
            (make-local-variable 'indent-line-function)
            (setq indent-line-function 'ig-indent-sql)))

(use-package mustache-mode
  :mode "\\.\\(mst|mustache\\)$")

(use-package gitignore-mod
  :mode "\\.\\(gitignore|jshintignore\\)$")

(use-package ntcmd
  :mode ("\\.bat$" . ntcmd-mode))

(use-package oz
  :mode ("\\.oz$" . oz-mode))

(autoload 'R-mode "ess-site.el" "" t)
(add-to-list 'auto-mode-alist '("\\.R$" . R-mode))

;; R indentation
(add-hook 'R-mode-hook
          (lambda ()
            (defvar ess-indent-level)
            (setq ess-indent-level tab-width)))

(dolist (extension
         '("\\.rake$"
           "Rakefile$"
           "\\.gemspec$"
           "\\.ru$"
           "Gemfile$"
           "Guardfile"
           "guardrc"
           "Vagrantfile"
           "Cheffile"))
  (add-to-list 'auto-mode-alist (cons extension 'ruby-mode)))

(use-package xahk-mode
  :mode "\\.ahk$")

(use-package erlang
  :mode
  ("\\(\\.hrl|\\.yrl|\\.app|\\.appSrc|\\.app.src|\\.rel|rebar.config\\)$" .
   erlang-mode)
  :init
  (progn
    (add-hook 'erlang-mode-hook
              (lambda ()
                (defvar erlang-indent-level)
                (defvar erlang-electric-commands)
                ;; Erlang indentation
                ;; Disable autocomplete
                (setq erlang-indent-level tab-width
                      erlang-electric-commands '())))))

;; (autoload ("\\.yaws$" . two-mode-mode))

(use-package yaml-mode
  :init
  (add-to-list 'auto-mode-alist '("\\.reek$" . yaml-mode)))

(use-package json-mode
  :init
  (add-to-list 'auto-mode-alist '("\\.jshintrc$" . json-mode))
  (add-to-list 'auto-mode-alist '("\\.bowerrc$" . json-mode)))

;; Embedded HTML/CSS/JS
(use-package mmm-mode
  :init
  (progn
    ;; ERB
    (defun sanityinc/ensure-mmm-erb-loaded ()
      (require 'mmm-erb))

    (require 'derived)

    (defun sanityinc/set-up-mode-for-erb (mode)
      (add-hook (derived-mode-hook-name mode) 'sanityinc/ensure-mmm-erb-loaded)
      (mmm-add-mode-ext-class mode "\\.erb$" 'erb))

    (let ((html-erb-modes '(html-mode html-erb-mode nxml-mode)))
      (dolist (mode html-erb-modes)
        (sanityinc/set-up-mode-for-erb mode)
        (mmm-add-mode-ext-class mode "\\.r?html\\(\\.erb\\)?$" 'html-js)
        (mmm-add-mode-ext-class mode "\\.r?html\\(\\.erb\\)?$" 'html-css)))

    (mapc 'sanityinc/set-up-mode-for-erb
          '(coffee-mode js-mode js2-mode js3-mode markdown-mode textile-mode))

    (mmm-add-mode-ext-class 'html-erb-mode "\\.jst\\.ejs$" 'ejs)

    (add-to-list 'auto-mode-alist '("\\.\\(r\\)?html\\(erb\\)?$" . html-erb-mode))
    (add-to-list 'auto-mode-alist '("\\.jst\\.ejs$"  . html-erb-mode))
    (mmm-add-mode-ext-class 'yaml-mode "\\.yaml$" 'erb)

    (dolist (mode (list 'js-mode 'js2-mode 'js3-mode))
      (mmm-add-mode-ext-class mode "\\.js\\.erb$" 'erb))

    ;; CSS
    (mmm-add-group
     'html-css
     '((css-cdata
        :submode css-mode
        :face mmm-code-submode-face
        :front "<style[^>]*>[ \t\n]*\\(//\\)?<!\\[CDATA\\[[ \t]*\n?"
        :back "[ \t]*\\(//\\)?]]>[ \t\n]*</style>"
        :insert ((?j js-tag nil @ "<style type=\"text/css\">"
                     @ "\n" _ "\n" @ "</script>" @)))
       (css
        :submode css-mode
        :face mmm-code-submode-face
        :front "<style[^>]*>[ \t]*\n?"
        :back "[ \t]*</style>"
        :insert ((?j js-tag nil @ "<style type=\"text/css\">"
                     @ "\n" _ "\n" @ "</style>" @)))
       (css-inline
        :submode css-mode
        :face mmm-code-submode-face
        :front "style=\""
        :back "\"")))
    (dolist (mode (list 'html-mode 'nxml-mode))
      (mmm-add-mode-ext-class mode "\\.r?html\\(\\.erb\\)?$" 'html-css))))

(use-package rainbow-mode
  :init
  (dolist (hook '(css-mode-hook html-mode-hook sass-mode-hook))
    (add-hook hook 'rainbow-mode)))

(use-package tbemail
  :mode ("\\.eml$" . tbemail-mode))

;;
;; Fix C family autoindent
;;
;; K&R style,
;; lining up parentheses as well.
;;
(setq gangnam-style
      '((tab-width . 2)
        (c-basic-offset . 2)
        (c-comment-only-line-offset . 0)
        (c-offsets-alist
         (arglist-close . c-lineup-close-paren)
         (statement-block-intro . +)
         (knr-argdecl-intro . 0)
         (substatement-open . 0)
         (substatement-label . 0)
         (label . 0)
         (statement-cont . +))))
(add-hook 'c-mode-common-hook
          (lambda ()
            (c-add-style "gangnam-style" gangnam-style t)

            (setq indent-tabs-mode nil
                  comment-start "// "
                  comment-end "")))

(use-package dart-mode
  :defer t
  :config
  (add-hook 'dart-mode-hook
            (lambda ()
              (c-add-style "dart" gangnam-style t))))

(use-package ack-and-a-half
  :bind (("C-x C-a" . ack-and-a-half)
         ("s-F" . ack-and-a-half)))
