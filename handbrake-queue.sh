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
	echo "Usage: handbrake-queue.sh -d {directory} -j {jobs.csv}"
	exit
	;;
esac

while [[ $# -gt 0 ]]
do
argv="$1"

case $argv in
	-d|--directory)
		directory="$2"
		shift
		shift
		;;
	-j|--jobs)
		jobfile="$2"
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

## Check if handbrake is running
psoutput=$(ps aux | grep -i "HandBrakeCLI -i" | awk '{print $11}')
for activeprocess in $psoutput; do
	if [ $activeprocess == "HandBrakeCLI" ] ;then
		except "HandBrakeCLI is running"
	fi
done
## read in job file
if [ $directory ]; then
	jobfile="$directory/$jobfile"
fi
while IFS=, read -r sourcefile outputfile audio subtitle forcedsubtitle
do
	echo "Source file : $sourcefile"
	echo "Output file : $outputfile"
	echo "Audio track : $audio"
	echo "Subtitle track : $subtitle"
	echo "Forced Subtitle track : $forcedsubtitle"
	echo "Source file : $sourcefile"
done < $jobfile
## launch convert-video.sh
echo "Do things"

