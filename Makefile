

fmt:
	dart format --set-exit-if-changed lib test

fix:
	dart format lib test

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
	mkdocs serve

build-docs:
	mkdocs build --site-dir build/website

build-cli:
	mkdir -p build
	dart compile exe cli/main.dart -o build/flauth-cli

.PHONY: fmt lint test fix gen perf serve build-docs build-cli
