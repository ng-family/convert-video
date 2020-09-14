#!/bin/bash

#handbrake-queue.sh
#
# This script queues jobs for convert-video.sh .
# 

## Error handler
except() {
	echo "Error: $1" >&2
	echo "Error: $1" >> $logfile
	exit ${2:-1}
}
OIFS=$IFS
logfile="/home/paul/Convert-Video/handbrake-queue.log"
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
	sourcefile="$directory/$sourcefile"
	outputfile="$directory/$outputfile"
else
	logfile="handbrake-queue.log"
fi
logfile="/home/paul/Convert-Video/handbrake-queue.log"
echo "`date -u`" >> $logfile
if [[ -f "$jobfile" ]]; then
	while IFS=, read -r sourcefile outputfile audio subtitle forcedsubtitle
	do
		if [ ! "$sourcefile" ]; then
			except "Line in jobs file does not have source argument"
		fi
		if [ ! "$outputfile" ]; then
			except "Line in jobs file does not have output argument"
		fi
		if [ ! "$audio" ]; then
			except "Line in jobs file does not have audio argument"
		fi
		convertoptions=('-i' "$sourcefile" '-o' "$outputfile" '-a' $audio)
		if [ "$subtitle" ]; then
			convertoptions+=('-s' $subtitle)
		fi
		if [ "$forcedsubtitle" ]; then
			convertoptions+=('-fs' $forcedsubtitle)
		fi
		for i in "${convertoptions[@]}"; do echo "$i"; done
		#$scriptfile "${command[@]}" # Do it!
	done < $jobfile
else
	except "No job file!"
fi
## Clean up jobs csv and save log
mv -f "$jobfile" "$jobfile.old"
