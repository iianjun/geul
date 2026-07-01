.PHONY: lint lint-fix build build-xcode kill install install-hooks check-no-docs-staged test-repo-policy release-build release-package release-notarize release-verify release-cask release-github

lint:
	swiftlint lint --strict

lint-fix:
	swiftlint lint --fix

check-no-docs-staged:
	@scripts/check-no-docs-staged

test-repo-policy:
	@sh Tests/RepoPolicyTests/NoDocsPreCommitTest.sh

install-hooks:
	git config core.hooksPath .githooks
	@echo "Installed Git hooks: core.hooksPath=.githooks"

build:
	swift build

build-xcode:
	xcodebuild -project geul.xcodeproj -scheme geul -configuration Debug build

kill:
	@pkill -f geul 2>/dev/null || true

install: build-xcode
	@set -e; \
	BUILT=$$(xcodebuild -project geul.xcodeproj -scheme geul -showBuildSettings 2>/dev/null | grep ' BUILT_PRODUCTS_DIR' | sed 's/.*= //'); \
	BUILT_APP="$$BUILT/geul.app"; \
	INSTALL_APP="/Applications/geul.app"; \
	WRAPPER="$$INSTALL_APP/Contents/Resources/Resources/ge"; \
	PRIMARY="/usr/local/bin/ge"; \
	FALLBACK="/usr/local/bin/geul"; \
	LEGACY="/usr/local/bin/gl"; \
	BUILT_WRAPPER="$$BUILT_APP/Contents/Resources/Resources/ge"; \
	if [ ! -x "$$BUILT_WRAPPER" ]; then \
	  echo "Missing CLI wrapper: $$BUILT_WRAPPER" >&2; \
	  exit 1; \
	fi; \
	if [ -d "$$INSTALL_APP" ]; then \
	  EXISTING_ID=$$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$$INSTALL_APP/Contents/Info.plist" 2>/dev/null || true); \
	  if [ "$$EXISTING_ID" != "com.geul.app" ]; then \
	    echo "Refusing to overwrite unmanaged app: $$INSTALL_APP" >&2; \
	    exit 1; \
	  fi; \
	  rm -rf "$$INSTALL_APP"; \
	fi; \
	/usr/bin/ditto "$$BUILT_APP" "$$INSTALL_APP"; \
	/usr/bin/touch "$$INSTALL_APP"; \
	for link in "$$PRIMARY" "$$FALLBACK"; do \
	  if [ -L "$$link" ]; then \
	    TARGET=$$(readlink "$$link"); \
	    case "$$TARGET" in \
	      "$$INSTALL_APP/Contents/Resources/Resources/ge"|"$$INSTALL_APP/Contents/Resources/Resources/geul"|"$$INSTALL_APP/Contents/Resources/Resources/gl"|\
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
	    "$$INSTALL_APP/Contents/Resources/Resources/ge"|"$$INSTALL_APP/Contents/Resources/Resources/geul"|"$$INSTALL_APP/Contents/Resources/Resources/gl"|\
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
	  if [ -d "$$stale" ]; then $$LSREG -u "$$stale" >/dev/null 2>&1 || true; fi; \
	done; \
	$$LSREG -f "$$INSTALL_APP"; \
	echo "Installed: /usr/local/bin/ge and /usr/local/bin/geul (LaunchServices -> $$INSTALL_APP)"

release-build:
	scripts/release/build.sh

release-package:
	scripts/release/package-dmg.sh

release-notarize:
	scripts/release/notarize.sh

release-verify:
	scripts/release/verify.sh

release-cask:
	scripts/release/update-cask.sh

release-github:
	scripts/release/github-release.sh
