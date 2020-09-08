#!/bin/bash

#handbrake-queue.sh
#
# This script queues jobs for convert-video.sh .
# 

## Error handler
except() {
	echo "Error: $1" >&2
	exit ${2:-1}
}
OIFS=$IFS
## Parse arguments
case $1 in
	-h|--help)
	echo "Usage: handbrake-queue.sh -j {jobs.txt}"
	exit
	;;
esac

while [[ $# -gt 0 ]]
do
argv="$1"

case $argv in
	-j|--jobs)
		readonly jobfile="$2"
		shift # position arguments to next 
		shift
		;;
	*)
		except "Unknown input $1"
		shift
		;;
esac
done

## Required arguments
if [ ! "$jobfile" ]; then
	except "Cannot find job file"
fi

## check if handbrake is running

## read in job file

## launch convert-video.sh


