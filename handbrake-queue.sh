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
	echo "Usage: handbrake-queue.sh -s {script} -d {directory} -j {jobs.csv}"
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
	-s|--script)
		scriptfile="$2"
		shift
		shift
		;;
	*)
		except "Unknown input $1"
		shift
		;;
esac
done

## Required arguments
if [ ! "$scriptfile" ]; then
	except "Missing script location"
fi
if [ ! "$jobfile" ]; then
	except "Missing job file"
fi

## Check if handbrake is running
psoutput=$(ps aux | grep -i "HandBrakeCLI -i" | awk '{print $11}')
for activeprocess in $psoutput; do
	if [ $activeprocess == "HandBrakeCLI" ] ;then
		except "HandBrakeCLI is running"
	fi
done

## Convert videos
if [ $directory ]; then
	jobfile="$directory/$jobfile"
	logfile="$directory/handbrake-queue.log"
else
	logfile="handbrake-queue.log"
fi
echo "`date -u`" >> $logfile
while IFS=, read -r sourcefile outputfile audio subtitle forcedsubtitle
do
	command="$scriptfile"
	if [ ! "$sourcefile" ]; then
		except "Line in jobs file does not have source argument"
	fi
	command="$command -i $directory/$sourcefile"
	if [ ! "$outputfile" ]; then
		except "Line in jobs file does not have output argument"
	fi
	command="$command -o $directory/$outputfile"
	if [ ! "$audio" ]; then
		except "Line in jobs file does not have audio argument"
	fi
	command="$command -a $audio"
	if [ "$subtitle" ]; then
		command="$command -s $subtitle"
	fi
	if [ "$forcedsubtitle" ]; then
		command="$command -fs $forcedsubtitle"
	fi
	echo "$command" >> $logfile
	$command # Do it!
done < $jobfile
## Clean up jobs csv and save log
echo "rm $directory/$jobfile"
