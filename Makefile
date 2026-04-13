.PHONY: lint lint-fix build build-xcode kill install

lint:
	swiftlint lint --strict

lint-fix:
	swiftlint lint --fix

build:
	swift build

build-xcode:
	xcodebuild -project geul.xcodeproj -scheme geul -configuration Debug build

kill:
	@pkill -f geul 2>/dev/null || true

install: build-xcode
	@BUILT=$$(xcodebuild -project geul.xcodeproj -scheme geul -showBuildSettings 2>/dev/null | grep ' BUILT_PRODUCTS_DIR' | sed 's/.*= //'); \
	ln -sf "$$BUILT/geul.app/Contents/Resources/Resources/geul" /usr/local/bin/geul
	@echo "Installed: /usr/local/bin/geul"
