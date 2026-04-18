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
	APP="$$BUILT/geul.app"; \
	ln -sf "$$APP/Contents/Resources/Resources/geul" /usr/local/bin/geul; \
	LSREG=/System/Library/Frameworks/CoreServices.framework/Versions/A/Frameworks/LaunchServices.framework/Versions/A/Support/lsregister; \
	for stale in $$HOME/Library/Developer/Xcode/DerivedData/geul-*/Build/Products/Debug/geul.app; do \
	  if [ -d "$$stale" ] && [ "$$stale" != "$$APP" ]; then $$LSREG -u "$$stale" >/dev/null 2>&1 || true; fi; \
	done; \
	$$LSREG -f "$$APP"; \
	echo "Installed: /usr/local/bin/geul (LaunchServices -> $$APP)"
