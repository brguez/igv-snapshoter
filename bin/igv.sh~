#!/bin/sh

#This script is intended for launch on *nix machines

#-Xmx1000m indicates 1000 mb of memory (I modified this value. The default was 4000), adjust number up or down as needed
#Script must be in the same directory as igv.jar
#Add the flag -Ddevelopment = true to use features still in development
prefix=`dirname $(readlink $0 || echo $0)`
exec java -Xmx1000m \
	-Dapple.laf.useScreenMenuBar=true \
	-Djava.net.preferIPv4Stack=true \
	-jar "$prefix"/igv.jar "$@"
