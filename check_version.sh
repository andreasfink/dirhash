#!/bin/bash
LOCAL_VERSION=`cat VERSION`
VERSION_CHECK=`curl http://dirhash.fink.org/version.php?version=$LOCAL_VERSION 2>/dev/null`
if [ "$VERSION_CHECK" == "current" ]
then
	exit 0;
fi
echo "$VERSION_CHECK"



