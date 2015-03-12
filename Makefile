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


Build/Products/Debug/dirhash: version.h
	xcodebuild -configuration Debug -target dirhash

Build/Products/Debug/dirhashdiff: version.h
	xcodebuild -configuration Debug -target dirhashdiff
	
Build/Products/Release/dirhash: version.h
	xcodebuild -configuration Release -target dirhash

Build/Products/Release/dirhashdiff: version.h
	xcodebuild -configuration Release -target dirhashdiff

version.h:	VERSION
	echo "#define VERSION \"`cat VERSION`\"" > version.h
	
clean:
	rm -rf Build/

install: Build/Products/Debug/dirhash Build/Products/Debug/dirhashdiff
	-./check_version.sh
	mkdir -p $(DESTDIR)/usr/local/bin
	install -m 755 -o root -g wheel -m 755 Build/$(CONF)/dirhash $(DESTDIR)/usr/local/bin/dirhash
	install -m 755 -o root -g wheel -m 755 Build/$(CONF)/dirhashdiff $(DESTDIR)/usr/local/bin/dirhashdiff

pkg:
	xcodebuild $(CONFOPTION)
	if [ -d "install_root" ]; then rm -rf install_root; fi
	mkdir -p "install_root/usr/local/bin"
	cp Build/$(CONF)/dirhash install_root/usr/local/bin/dirhash
	cp Build/$(CONF)/dirhashdiff install_root/usr/local/bin/dirhashdiff
	OUTPUTFILE=
	pkgbuild --root install_root --install-location / $(INSTALLER_SIGN) --ownership recommended --version "`cat VERSION`" --identifier $(PROJECT_ID) "$(PKGFILE)"

