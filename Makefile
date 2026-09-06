.PHONY: help get clean codegen build-apk-release build-apk-split build-appbundle build-ios build-macos test analyze format run install-apk fresh-start

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
build-apk-release: ## Build release APK with icon tree-shaking
	@echo "🚀 Building Release APK (with Tree Shake Icons)..."
	flutter build apk --release --tree-shake-icons
	@echo "✅ APK generated at: build/app/outputs/flutter-apk/app-release.apk"

build-apk-split: ## Build split-per-ABI APKs (~20MB each) for faster install
	@echo "🚀 Building Split-per-ABI APKs (arm64, arm32, x86_64)..."
	flutter build apk --release --split-per-abi --tree-shake-icons
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
install-apk: ## Install latest release APK on connected Android device/emulator
	@echo "📲 Installing release APK onto device via ADB..."
	adb install -r build/app/outputs/flutter-apk/app-release.apk

run: ## Run app on connected device in debug mode
	@echo "▶️ Launching Flutter app..."
	flutter run

run-release: ## Run app on connected device in release mode
	@echo "▶️ Launching Flutter app in Release mode..."
	flutter run --release

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
