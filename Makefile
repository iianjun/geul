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
	@set -e; \
	BUILT=$$(xcodebuild -project geul.xcodeproj -scheme geul -showBuildSettings 2>/dev/null | grep ' BUILT_PRODUCTS_DIR' | sed 's/.*= //'); \
	APP="$$BUILT/geul.app"; \
	WRAPPER="$$APP/Contents/Resources/Resources/ge"; \
	PRIMARY="/usr/local/bin/ge"; \
	FALLBACK="/usr/local/bin/geul"; \
	LEGACY="/usr/local/bin/gl"; \
	if [ ! -x "$$WRAPPER" ]; then \
	  echo "Missing CLI wrapper: $$WRAPPER" >&2; \
	  exit 1; \
	fi; \
	for link in "$$PRIMARY" "$$FALLBACK"; do \
	  if [ -L "$$link" ]; then \
	    TARGET=$$(readlink "$$link"); \
	    case "$$TARGET" in \
	      "$$APP/Contents/Resources/Resources/ge"|"$$APP/Contents/Resources/Resources/geul"|"$$APP/Contents/Resources/Resources/gl"|\
	      "$$HOME/Library/Developer/Xcode/DerivedData/geul-"*/Build/Products/Debug/geul.app/Contents/Resources/Resources/ge|\
	      "$$HOME/Library/Developer/Xcode/DerivedData/geul-"*/Build/Products/Debug/geul.app/Contents/Resources/Resources/geul|\
	      "$$HOME/Library/Developer/Xcode/DerivedData/geul-"*/Build/Products/Debug/geul.app/Contents/Resources/Resources/gl) ;; \
	      *) echo "Refusing to overwrite unmanaged $$link -> $$TARGET" >&2; exit 1 ;; \
	    esac; \
	  elif [ -e "$$link" ]; then \
	    echo "Refusing to overwrite unmanaged $$link (not a symlink)" >&2; \
	    exit 1; \
	  fi; \
	done; \
	if [ -L "$$LEGACY" ]; then \
	  LEGACY_TARGET=$$(readlink "$$LEGACY"); \
	  case "$$LEGACY_TARGET" in \
	    "$$APP/Contents/Resources/Resources/ge"|"$$APP/Contents/Resources/Resources/geul"|"$$APP/Contents/Resources/Resources/gl"|\
	    "$$HOME/Library/Developer/Xcode/DerivedData/geul-"*/Build/Products/Debug/geul.app/Contents/Resources/Resources/ge|\
	    "$$HOME/Library/Developer/Xcode/DerivedData/geul-"*/Build/Products/Debug/geul.app/Contents/Resources/Resources/geul|\
	    "$$HOME/Library/Developer/Xcode/DerivedData/geul-"*/Build/Products/Debug/geul.app/Contents/Resources/Resources/gl) rm "$$LEGACY" ;; \
	    *) echo "Leaving unmanaged $$LEGACY -> $$LEGACY_TARGET" ;; \
	  esac; \
	elif [ -e "$$LEGACY" ]; then \
	  echo "Leaving unmanaged $$LEGACY (not a symlink)"; \
	fi; \
	ln -sf "$$WRAPPER" "$$PRIMARY"; \
	ln -sf "$$WRAPPER" "$$FALLBACK"; \
	LSREG=/System/Library/Frameworks/CoreServices.framework/Versions/A/Frameworks/LaunchServices.framework/Versions/A/Support/lsregister; \
	for stale in $$HOME/Library/Developer/Xcode/DerivedData/geul-*/Build/Products/Debug/geul.app; do \
	  if [ -d "$$stale" ] && [ "$$stale" != "$$APP" ]; then $$LSREG -u "$$stale" >/dev/null 2>&1 || true; fi; \
	done; \
	$$LSREG -f "$$APP"; \
	echo "Installed: /usr/local/bin/ge and /usr/local/bin/geul (LaunchServices -> $$APP)"
