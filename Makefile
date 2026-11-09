.PHONY: build test install

build:
	./scripts/build.sh

test:
	./scripts/test.sh

install: build
	ditto ".build/World Clocks.app" "/Applications/World Clocks.app"
	xattr -cr "/Applications/World Clocks.app"
	codesign --force --sign - "/Applications/World Clocks.app"
	@echo "Installed /Applications/World Clocks.app"
