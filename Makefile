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
	WRAPPER="$$APP/Contents/Resources/Resources/gl"; \
	NEW="/usr/local/bin/gl"; \
	OLD="/usr/local/bin/geul"; \
	if [ ! -x "$$WRAPPER" ]; then \
	  echo "Missing CLI wrapper: $$WRAPPER" >&2; \
	  exit 1; \
	fi; \
	if [ -L "$$OLD" ]; then \
	  OLD_TARGET=$$(readlink "$$OLD"); \
	  case "$$OLD_TARGET" in \
	    *"/geul.app/Contents/Resources/Resources/geul"|*"/geul.app/Contents/Resources/Resources/gl") rm "$$OLD" ;; \
	    *) echo "Refusing to remove unmanaged $$OLD -> $$OLD_TARGET" >&2; exit 1 ;; \
	  esac; \
	elif [ -e "$$OLD" ]; then \
	  echo "Refusing to remove unmanaged $$OLD (not a symlink)" >&2; \
	  exit 1; \
	fi; \
	ln -sf "$$WRAPPER" "$$NEW"; \
	LSREG=/System/Library/Frameworks/CoreServices.framework/Versions/A/Frameworks/LaunchServices.framework/Versions/A/Support/lsregister; \
	for stale in $$HOME/Library/Developer/Xcode/DerivedData/geul-*/Build/Products/Debug/geul.app; do \
	  if [ -d "$$stale" ] && [ "$$stale" != "$$APP" ]; then $$LSREG -u "$$stale" >/dev/null 2>&1 || true; fi; \
	done; \
	$$LSREG -f "$$APP"; \
	echo "Installed: /usr/local/bin/gl (LaunchServices -> $$APP)"
