PREFIX ?= /usr/local
BINDIR ?= $(PREFIX)/bin
DATADIR ?= $(PREFIX)/share/dkariio-linux-app-catalog

.PHONY: all test install uninstall clean

all: test

test:
	./tests/run.sh

install: test
	install -Dm755 linux-catalog.sh "$(DESTDIR)$(BINDIR)/dkariio-catalog"
	install -d "$(DESTDIR)$(DATADIR)/catalog" "$(DESTDIR)$(DATADIR)/locales"
	install -m644 catalog/*.tsv "$(DESTDIR)$(DATADIR)/catalog/"
	install -m644 locales/*.sh "$(DESTDIR)$(DATADIR)/locales/"

uninstall:
	rm -f "$(DESTDIR)$(BINDIR)/dkariio-catalog"
	rm -rf "$(DESTDIR)$(DATADIR)"

clean:
	@true
