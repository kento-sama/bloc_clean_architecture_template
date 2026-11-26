KNOWN_TARGETS := help module remove-module rename-project fresh build-web run-web run-web-no-build build-android-local build-android-release build-ios-local patrol-test-regression test-report
.PHONY: $(KNOWN_TARGETS)

ifeq ($(OS),Windows_NT)
DART ?= dart.bat
else
DART ?= dart
endif

ifneq ($(filter module remove-module,$(MAKECMDGOALS)),)
TARGET_MODULE_COMMAND := $(firstword $(MAKECMDGOALS))
ifneq ($(words $(MAKECMDGOALS)),2)
ifeq ($(TARGET_MODULE_COMMAND),module)
$(error Usage: make module <snake_case_name>)
else
$(error Usage: make remove-module <snake_case_name>)
endif
endif
ifneq ($(filter $(word 2,$(MAKECMDGOALS)),$(KNOWN_TARGETS)),)
$(error Module name cannot be a Makefile target)
endif
override MODULE_NAME := $(word 2,$(MAKECMDGOALS))
export MODULE_NAME

# The second goal is an argument, not another target.
.DEFAULT:
	@:
endif

ifneq ($(filter rename-project,$(MAKECMDGOALS)),)
ifneq ($(words $(MAKECMDGOALS)),2)
$(error Usage: make rename-project <snake_case_name>)
endif
ifneq ($(filter $(word 2,$(MAKECMDGOALS)),$(KNOWN_TARGETS)),)
$(error Project name cannot be a Makefile target)
endif
override PROJECT_NAME := $(word 2,$(MAKECMDGOALS))
export PROJECT_NAME

# The second goal is an argument, not another target.
.DEFAULT:
	@:
endif
 
help:
	@echo "Makefile - Flutter App Build Automation"
	@echo ""
	@echo "Available targets:"
	@echo "  module NAME             Scaffold a clean-architecture feature"
	@echo "  remove-module NAME      Delete a generated feature module"
	@echo "  rename-project NAME     Rename the pubspec package and related project files"
	@echo "  fresh                   Cleans build artifacts and regenerates code"
	@echo "  build-web               Builds Flutter web application (dev ENV)"
	@echo "  run-web                 Runs the app on a web-server after building"
	@echo "  run-web-no-build        Runs the app on a web-server without building"
	@echo "  build-android-local     Builds debug Android APK and installs on connected device"
	@echo "  build-android-release   Builds release-signed Android APK (requires signing config)"
	@echo ""
	@echo "Prerequisites: Flutter SDK, Dart SDK, Android SDK/tools, ADB, Allure CLI"
	@echo ""
	@echo "Usage: make <target>  (run 'make' with no args to show this help)"
	@echo "       make module <module_name>"
	@echo "       make remove-module <module_name>"
	@echo "       make rename-project <package_name>"
	@echo ""

module:
	@$(DART) run bin/clean_module.dart $(MODULE_NAME)

remove-module:
	@$(DART) run bin/remove_clean_module.dart $(MODULE_NAME)

rename-project:
	@$(DART) run bin/rename_project.dart $(PROJECT_NAME)
 
fresh:
	@echo "Refreshing build artifacts"
	fvm use
	fvm flutter clean
	fvm flutter pub get --no-example
	fvm dart run build_runner clean
	fvm dart run build_runner build --delete-conflicting-outputs
	@echo "Refresh done"
 
build-web:
	@echo "Running codegen and building web"
	fvm flutter build web --release
	@echo "Web build done: build/web/"
 
run-web:
	@echo "Ensure your .env or environment variables are set before running. Launching web-server"
	fvm flutter pub get
	fvm flutter build web
	cd build/web && python -m http.server 8080
 
run-web-no-build:
	@echo "Ensure your .env or environment variables are set before running. Launching web-server without building"
	fvm flutter run -d web-server
 
 
build-android-local:
	@echo "Running codegen and building Android (local non-release)"
	fvm flutter build apk --debug --split-per-abi
	adb install -r build/app/outputs/flutter-apk/app-x86_64-debug.apk
	@echo "Local Android build done: build/app/outputs/flutter-apk/"
 
build-android-release:
	@echo "Running codegen and building Android (release)"
	# Attempt release build; requires signing config in android/key.properties
	fvm flutter build apk --release --split-per-abi
	@echo "Release Android build done: build/app/outputs/flutter-apk/"
 	
# maestro test test/android/login --format junit --output test/reports/android_test.xml
# allure generate test/reports --clean && allure open
 
# maestro test test/web/login --format junit --output test/reports/web_test.xml
# allure generate test/reports --clean && allure open
 
# lcov-viewer lcov -o ./report-output-directory ./patrol_lcov.info
 