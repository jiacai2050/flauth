

fmt:
	dart format --set-exit-if-changed lib test cli

fix:
	dart format lib test cli

lint:
	flutter analyze

test:
	flutter test

gen:
	#dart run flutter_launcher_icons:generate --override
	flutter pub run flutter_launcher_icons

perf:
	flutter run --profile -d mac

serve:
	cd docs && mdbook serve

build-docs:
	cd docs && mdbook build

build-cli:
	mkdir -p build
	dart compile exe cli/main.dart -o build/flauth-cli

.PHONY: fmt lint test fix gen perf serve build-docs build-cli
