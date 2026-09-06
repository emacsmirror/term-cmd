all: test

.PHONY: test
test:
	rm -rf dist
	rm -rf emacs.d/elpa/term-cmd-1.4.0
	cask package
	cask install
	cask exec ert-runner
	test/test-interactive.sh
