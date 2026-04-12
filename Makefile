.PHONY: lint lint-fix build

lint:
	swiftlint lint --strict

lint-fix:
	swiftlint lint --fix

build:
	swift build
