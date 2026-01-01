

fmt:
	dart format --set-exit-if-changed lib

fix:
	dart format lib

lint:
	flutter analyze

test:
	flutter test

.PHONY: fmt lint test fix
