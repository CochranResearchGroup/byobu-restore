.PHONY: help install uninstall lint test

help:
	@echo "Targets: install, uninstall, lint, test"

install:
	@./install.sh

uninstall:
	@./uninstall.sh

lint:
	@bash -n bin/byobu-session-state
	@bash -n bin/byobu-restore
	@bash -n libexec/byobu-session-autosave
	@bash -n install.sh
	@bash -n uninstall.sh
	@bash -n tests/cli.sh
	@bash -n tests/smoke.sh
	@bash -n tests/restore.sh
	@bash -n tests/install.sh

test: lint
	@./tests/cli.sh
	@./tests/smoke.sh
	@./tests/restore.sh
	@./tests/install.sh
