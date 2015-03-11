##
# File: Makefile
# Project "dirhash"
# (c) 2015 Andreas Fink (andreas@fink.org)
#
#

PROJECT_NAME=dirhash
VERSION=`cat VERSION`
PROJECT_ID=org.fink.$(PROJECT_NAME)
PKGFILE=$(PROJECT_NAME)_`cat VERSION`.pkg
#INSTALLER_CERT="Developer ID Installer: SMSRelay AG"
#INSTALLER_SIGN=--sign "Developer ID Installer: SMSRelay AG"
CONF=Release
CONFOPTION=-configuration $(CONF)
BUILD_DIR=Build



Build/Products/Debug/dirhash:
	xcodebuild $(CONFOPTION)

clean:
	rm -f Build

install: Build/Products/Debug/dirhash
	xcodebuild $(CONFOPTION)
	mkdir -p $(DESTDIR)/usr/local/bin
	install -m 755 -o root -g wheel -m 755 Build/$(CONF)/dirhash $(DESTDIR)/usr/local/bin/dirhash

pkg:
	xcodebuild $(CONFOPTION)
	if [ -d "install_root" ]; then rm -rf install_root; fi
	mkdir -p "install_root/usr/local/bin"
	cp Build/$(CONF)/dirhash install_root/usr/local/bin/dirhash
	OUTPUTFILE=
	pkgbuild --root install_root --install-location / $(INSTALLER_SIGN) --ownership recommended --version "`cat VERSION`" --identifier $(PROJECT_ID) "$(PKGFILE)"

