((js-json-mode . ((eval . (progn
                            (adria-json-on-save-mode)))))
 (python-mode . ((eval . (progn
                           (add-hook 'before-save-hook #'adria-python-format-buffer nil t)))))
 (nil . ((unison-profile . "sae"))))
