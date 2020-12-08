prefix ?= /usr/local
bindir = $(prefix)/bin

build:
	swift build -c release --disable-sandbox

install: build
	install ".build/release/xcconfig-crypt" "$(bindir)/xcconfig-crypt"

uninstall:
	rm -rf "$(bindir)/xcconfig-crypt"

clean:
	rm -rf .build

.PHONY: build install uninstall clean
