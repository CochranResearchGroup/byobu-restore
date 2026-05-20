.PHONY: help install uninstall lint test

help:
	@echo "Targets: install, uninstall, lint, test"

install:
	@./install.sh

uninstall:
	@./uninstall.sh

lint:
	@bash -n bin/byobu-session-state
	@bash -n install.sh
	@bash -n uninstall.sh
	@bash -n tests/cli.sh
	@bash -n tests/smoke.sh

test: lint
	@./tests/cli.sh
	@./tests/smoke.sh
