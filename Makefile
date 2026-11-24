# make install [PREFIX=/usr] [DESTDIR=...]   |   make check
PREFIX ?= /usr
DATADIR = $(PREFIX)/share/grace-candyland
SHELLDIR = $(DATADIR)/shell
BINS = grace-candyland grace-launch grace-settings grace-approve grace-cortex
SUBST = sed -e 's|@DATADIR@|$(DATADIR)|g' -e 's|@SHELLDIR@|$(SHELLDIR)|g'

install:
	find shell -type f -exec install -Dm644 {} "$(DESTDIR)$(DATADIR)/{}" \;
	install -Dm644 data/desktop.conf "$(DESTDIR)$(DATADIR)/desktop.conf"
	$(SUBST) hypr/hyprland.lua | install -Dm644 /dev/stdin "$(DESTDIR)$(DATADIR)/hyprland.lua"
	$(SUBST) data/hypridle.conf | install -Dm644 /dev/stdin "$(DESTDIR)$(DATADIR)/hypridle.conf"
	for b in $(BINS); do $(SUBST) bin/$$b | install -Dm755 /dev/stdin "$(DESTDIR)$(PREFIX)/bin/$$b" || exit 1; done
	install -Dm644 data/grace-candyland.desktop "$(DESTDIR)$(PREFIX)/share/wayland-sessions/grace-candyland.desktop"
	install -Dm644 data/grace-settings.desktop "$(DESTDIR)$(PREFIX)/share/applications/grace-settings.desktop"
	install -Dm644 data/icons/grace-settings.svg "$(DESTDIR)$(PREFIX)/share/icons/hicolor/scalable/apps/grace-settings.svg"
	install -Dm644 data/org.graceos.CortexCouncil.desktop "$(DESTDIR)$(PREFIX)/share/applications/org.graceos.CortexCouncil.desktop"
	install -Dm644 data/icons/org.graceos.CortexCouncil.svg "$(DESTDIR)$(PREFIX)/share/icons/hicolor/scalable/apps/org.graceos.CortexCouncil.svg"
	install -Dm755 apps/candysole/candysole "$(DESTDIR)$(PREFIX)/bin/candysole"
	install -Dm644 apps/candysole/org.graceos.CandySole.desktop "$(DESTDIR)$(PREFIX)/share/applications/org.graceos.CandySole.desktop"
	install -Dm644 apps/candysole/org.graceos.CandySole.svg "$(DESTDIR)$(PREFIX)/share/icons/hicolor/scalable/apps/org.graceos.CandySole.svg"

uninstall:
	rm -rf "$(DESTDIR)$(DATADIR)"
	for b in $(BINS); do rm -f "$(DESTDIR)$(PREFIX)/bin/$$b"; done
	rm -f "$(DESTDIR)$(PREFIX)/share/wayland-sessions/grace-candyland.desktop" \
	      "$(DESTDIR)$(PREFIX)/share/applications/grace-settings.desktop" \
	      "$(DESTDIR)$(PREFIX)/share/icons/hicolor/scalable/apps/grace-settings.svg" \
	      "$(DESTDIR)$(PREFIX)/share/applications/org.graceos.CortexCouncil.desktop" \
	      "$(DESTDIR)$(PREFIX)/share/icons/hicolor/scalable/apps/org.graceos.CortexCouncil.svg" \
	      "$(DESTDIR)$(PREFIX)/bin/candysole" "$(DESTDIR)$(PREFIX)/share/applications/org.graceos.CandySole.desktop" \
	      "$(DESTDIR)$(PREFIX)/share/icons/hicolor/scalable/apps/org.graceos.CandySole.svg"

# Static checks; tests/approve.sh additionally needs a running session.
# Hyprland 0.57+ reads only Lua. The config loads ~/.config/grace/monitors.lua and hyprland.lua when they
# exist; verify with a sample of each, and give Hyprland the XDG_RUNTIME_DIR it needs (unset in CI).
check:
	shellcheck bin/* tests/*.sh
	tmp=$$(mktemp -d) && $(MAKE) -s install DESTDIR=$$tmp && \
	  mkdir -p $$tmp/home/.config/grace && cp tests/monitors.lua tests/hyprland.lua $$tmp/home/.config/grace/ && \
	  mkdir -m700 $$tmp/run && HOME=$$tmp/home XDG_RUNTIME_DIR=$$tmp/run Hyprland --verify-config --config $$tmp$(DATADIR)/hyprland.lua; s=$$?; rm -rf $$tmp; exit $$s

.PHONY: install uninstall check
