.PHONY: help get clean codegen build-apk-release build-apk-split build-appbundle build-ios build-macos test analyze format run install-apk fresh-start wireless connect-wireless run-wireless mirror

# Default target
all: help

## -----------------------------------------------------------------------------
## 📋 HELP MENU
## -----------------------------------------------------------------------------
help: ## Show this help message with available commands
	@echo "╔══════════════════════════════════════════════════════════════════════╗"
	@echo "║      💰 SPENDWISE - EXPENSE TRACKER & KHATABOOK MAKEFILE             ║"
	@echo "╚══════════════════════════════════════════════════════════════════════╝"
	@echo ""
	@echo "Usage: make [command]"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'
	@echo ""

## -----------------------------------------------------------------------------
## 📦 DEPENDENCY & CODEGEN COMMANDS
## -----------------------------------------------------------------------------
get: ## Get all Flutter dependencies
	@echo "📦 Getting Flutter dependencies..."
	flutter pub get

codegen: ## Run build_runner (ObjectBox code generation)
	@echo "⚙️ Generating ObjectBox models and database bindings..."
	dart run build_runner build --delete-conflicting-outputs

watch: ## Watch mode for code generation
	@echo "👀 Watching for entity/model changes..."
	dart run build_runner watch --delete-conflicting-outputs

## -----------------------------------------------------------------------------
## 🏗️ BUILD COMMANDS (WITH TREE-SHAKE & OPTIMIZATIONS)
## -----------------------------------------------------------------------------
build: build-apk-release ## Alias for build-apk-release
build-release: build-apk-release ## Alias for build-apk-release

build-apk-release: ## Build release APK with icon tree-shaking
	@echo "🚀 Building Release APK (with Tree Shake Icons)..."
	flutter build apk --release --tree-shake-icons
	@echo "✅ APK generated at: build/app/outputs/flutter-apk/app-release.apk"

build-apk-split: ## Build split-per-ABI APKs (~20MB each) with obfuscation and symbol stripping
	@echo "🚀 Building Obfuscated Split-per-ABI APKs (arm64, arm32, x86_64)..."
	flutter build apk --release --split-per-abi --tree-shake-icons --obfuscate --split-debug-info=build/app/outputs/symbols
	@echo "✅ Split APKs generated at: build/app/outputs/flutter-apk/"

build-apk-obfuscate: ## Build production obfuscated release APK
	@echo "🔒 Building Obfuscated Release APK with Split Debug Symbols..."
	flutter build apk --release --tree-shake-icons --obfuscate --split-debug-info=build/app/outputs/symbols
	@echo "✅ Obfuscated APK generated at: build/app/outputs/flutter-apk/app-release.apk"

build-appbundle: ## Build Android App Bundle (AAB) for Google Play Store
	@echo "🛍️ Building Release AppBundle (AAB)..."
	flutter build appbundle --release --tree-shake-icons
	@echo "✅ AAB generated at: build/app/outputs/bundle/release/app-release.aab"

build-ios: ## Build iOS release archive
	@echo "🍎 Building iOS Release..."
	flutter build ipa --release --tree-shake-icons

build-macos: ## Build macOS desktop release application
	@echo "🖥️ Building macOS Desktop Release..."
	flutter build macos --release

## -----------------------------------------------------------------------------
## 📲 EMULATOR / DEVICE ACTIONS
## -----------------------------------------------------------------------------
wireless: ## Auto-connect to Android device wirelessly (or specify: make wireless IP=192.168.x.x)
	@./scripts/connect_wireless.sh $(IP)

connect-wireless: wireless ## Alias for wireless

install-apk: ## Install latest release APK on connected Android device/emulator
	@echo "📲 Installing release APK onto device via ADB..."
	adb install -r build/app/outputs/flutter-apk/app-release.apk

run: ## Run app on connected device in debug mode
	@echo "▶️ Launching Flutter app..."
	flutter run

run-wireless: wireless ## Auto-connect wireless device and launch Flutter app
	@echo "▶️ Launching Flutter app wirelessly..."
	flutter run

run-release: ## Run app on connected device in release mode
	@echo "▶️ Launching Flutter app in Release mode..."
	flutter run --release

mirror: ## Mirror Android screen using scrcpy (handles multi-device automatically)
	@DEVICE=$$(adb devices | grep -v "List of devices" | grep -v "^$$" | grep "device$$" | grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+:5555' | head -n 1 | awk '{print $$1}'); \
	if [ -z "$$DEVICE" ]; then \
		DEVICE=$$(adb devices | grep -v "List of devices" | grep -v "^$$" | grep "device$$" | head -n 1 | awk '{print $$1}'); \
	fi; \
	if [ -z "$$DEVICE" ]; then \
		echo "⚠️ No ADB device found. Run 'make wireless' first."; \
		exit 1; \
	fi; \
	echo "🪞 Mirroring device: $$DEVICE..."; \
	scrcpy -s "$$DEVICE" --max-size=1024 --window-title="SpendWise Expense Tracker"


## -----------------------------------------------------------------------------
## 🧹 CLEANING & REBUILD
## -----------------------------------------------------------------------------
clean: ## Clean build cache and temporary files
	@echo "🧹 Cleaning Flutter build cache..."
	flutter clean
	rm -rf build/
	@echo "✅ Cache cleaned!"

fresh-start: clean get codegen ## Clean, re-fetch dependencies, and re-generate ObjectBox code
	@echo "✨ Project freshly initialized and ready to run!"

## -----------------------------------------------------------------------------
## 🧪 QUALITY & TESTING
## -----------------------------------------------------------------------------
analyze: ## Run static Dart analyzer
	@echo "🔍 Running Flutter Analyzer..."
	flutter analyze

test: ## Run unit and widget test suite
	@echo "🧪 Running Test Suite..."
	flutter test

format: ## Format all Dart files in lib and test
	@echo "💅 Formatting Dart code..."
	dart format lib test

check: format analyze test ## Run formatting, static analysis, and all tests
	@echo "🎉 All quality checks passed!"
