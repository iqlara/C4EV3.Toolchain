#!/bin/bash
# This is some wrapper to call the makefile fragment, which builds all toolchains
# - might be a good place for common preparations and final postprocessing

# Add some similiar line to your crontab (e.g. crontab -e)
# 0,5,10,15,20,25,30,35,40,45,50,55 *    * * * [ -f /home/csc/src/OSELAS.Toolchain-trunk/build_all.sh ] && \
#    ( cd /home/csc/src/OSELAS.Toolchain-trunk/ && ISCRON=yes bash build_all.sh )

buildlogfile=build_all_logs/build_all.log-`date +%y%m%d-%H%M`
lockfile=build_all.lock

set -e

if [ -z "${ISCRON}" ]; then set -x; 
else 
	# If ISCRON is not zero, setup some paths for ptxdist and other tools
	export PATH=/usr/bin:/usr/sbin/:/usr/local/bin:/usr/local/sbin:$PATH
fi

if ( set -o noclobber; echo "$$" > "$lockfile") 2> /dev/null; 
then
	trap 'rm -f "$lockfile"; exit $?' INT TERM EXIT
	
	# -- Update current SVN workcopy
	svn update -q

	# -- Start make, which check dependencies on the ptxconfig files stored in gstate
	# -- For each updated ptxconfig the toolchain is recompiled
	# -- Finaly a status file suitable for parsing is generated and stored in
	# --   gstate/OSELAS-BuildAll-Status.txt
	# -- The make process is started with via 'nice' to avoid high cpu-load on compile host
	mkdir -p build_all_logs
	if [ -n "${ISCRON}" ]; then
		nice -n 5 make -f build_all.mk > $buildlogfile
	else
		nice -n 5 make -f build_all.mk 
	fi 
	
	# -- Delete empty logfiles 
	if [ -e $buildlogfile ]; then if test -z "$(cat $buildlogfile)"; then rm $buildlogfile; fi; fi

	# -- Dump status file info
	#echo -e "\n\nStatus stored in gstate/OSELAS-BuildAll-Status.txt"
	make -f build_all.mk updatestatpage_forced
	
	# -- Remove lockfile
	rm -f $lockfile
	trap - INT TERM EXIT
else
	# -- Normally don't output things - causes mail flooding with cron. Debug stuff.
	echo "Build script running - lockfile \"$lockfile\" held by process $(cat $lockfile)"
fi

# -- ToDo ---------------------------------------------------------------------
# T=testing, X=done
#
# [ ] Fix creation of new install dirs - create a script to setup them all at once
#     (sudo hack for mkdir and NOPASSWD: ?)
# [ ] Checkout a new working copy of trunk for each chain, and do building in parallel
# [ ] Create a nice HTML output for the status showing the actual status of each chain
# [ ] Add checks to ensure consitency of ptxconfig files and install locations -
#       apply fixup-ptxconfigs.sh?
# [ ] Add code to create all install directory at once - so you have to enter the
#       sudo password only once, when this script started the first time.
# [ ] Remove link to installation directory from cross-toolchain.make?
#       We need some way to determine the installation path from outside ptxdist...
# [T] Add lock file for cron triggered operation

