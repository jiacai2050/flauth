

fmt:
	dart format --set-exit-if-changed lib

fix:
	dart format lib

lint:
	flutter analyze

test:
	flutter test

gen:
	#dart run flutter_launcher_icons:generate --override
	flutter pub run flutter_launcher_icons

perf:
	flutter run --profile -d mac

.PHONY: fmt lint test fix gen perf
