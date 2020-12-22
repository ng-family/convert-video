#!/bin/bash

#convert-audioonly.sh
#
# This script takes a mkv container file and output a mkv with first track 2.0, second track 5.1, third 7.1 if it exists..
# 

## Error handler
except() {
	echo "Error: $1" >&2
	exit ${2:-1}
}

## Manual Delay until I get handbrake-queue running.
if false; then
	c_time=$(date +%s)
	x_time=$(date -d '09/19/2020 2:00' +%s)
	d_time=$(( $x_time - $c_time ))
	echo "Going to sleep for $d_time seconds"
	sleep $d_time
fi

OIFS=$IFS
## Parse arguments
case $1 in
	-h|--help)
	echo "Usage: convert-audioonly.sh -i {input.mkv} -o {output.mkv} -a {main audio track number} [-a7 {7 channel audio}] [-a5 {5 channel audio}] | [-a2 {2 channel audio}] [-s]"
	exit
	;;
esac

while [[ $# -gt 0 ]]
do
argv="$1"

case $argv in
	-i|--input)
		readonly inputfile="$2"
		shift # position arguments to next 
		shift
		;;
	-o|--output)
		readonly outputfile="$2"
		shift # position arguments to next 
		shift
		;;
	-a|--audio)
		readonly audiotrack="$2"
		shift # position arguments to next
		shift
		;;
	-a7|--7chaudio)
		readonly audio7chtrack="$2"
		shift # position arguments to next
		shift
		;;
	-a5|--5chaudio)
		readonly audio5chtrack="$2"
		shift # position arguments to next
		shift
		;;
	-a2|--2chaudio)
		readonly audio2chtrack="$2"
		shift # position arguments to next
		shift
		;;
	-s|--subtitle)
		readonly subtitle="1"
		shift # position arguments to next
		;;
	*)
		except "Unknown input $1"
		shift
		;;
esac
done




## Required arguments
if [ ! "$inputfile" ]; then
	except "Missing source file"
fi
if [ ! "$outputfile" ]; then
	except "Missing required output"
fi
if [ "$inputfile" = "$outputfile" ]; then
	except "Destination same as source file"
fi
if [ ! "$audiotrack" ] && [ ! "$audio7chtrack" ] && [ ! "$audio5chtrack" ] && [ ! "$audio2chtrack" ]; then
	except "Missing audio track"
fi

## Determine Audio Channel and apply appropriate audio options
a7_options=""
a5_options=""
a2_options=""
scanresults=$(HandBrakeCLI --input "$inputfile" --scan 2>&1)
#ffmpeg -i /mnt/plexmedia/Movies/Family/The\ Grinch\ \(2018\).mkv -i ac3.mkv \-map 0:0 -map 0:1 -map 1:a -map 0:2 -map 0:3 -c:v copy -c:a:0 copy -c:a copy -c:a:1 copy -c:s copy /mnt/plexmedia/handbrake/The\ Grinch\ \(2018.mkv
if [ "$audiotrack" ]; then
	audiostream=$(grep -P '(?<=Audio).*[0-9]\.[0-9]' <<< "$scanresults")
	IFS=$'\n'
	audiochannels=(${audiostream//\\n/ })
	audiochannel="${audiochannels[$audiotrack-1]}"
	IFS=$OIFS
	if [[ $audiochannel == *"7.1"* ]]; then
		a7_options="-map  $audiotrack,$audiotrack,$audiotrack --aencoder av_aac,ac3,copy --mixdown stereo,5point1 --aname Stereo,\"Surround 5.1\",\"Surround 7.1\""
#	elif [[ $audiochannel == *"5.1"* ]]; then
#		autoselection+="5"
#		audio_options="--audio $audiotrack,$audiotrack --aencoder ca_aac,copy --mixdown stereo --aname Stereo,\"Surround 5.1\""
	else
	## Not sure use case here... only 2ch source...
		a2_options="-map 0:a copy"
	fi
fi
### Add Subtitles
if [ "$subtitle" ]; then
	subtitles_options="-map 0:s:0 -c:s copy"
else
	subtitles_options=""
fi
### Encode Video
#time "HandBrakeCLI" $video_options --encopts $encoder_options $audio_options $subtitles_options --input "$inputfile" --output "$outputfile" 2>&1
echo "ffmpeg" -i "$inputfile" $subtitles_options "$outputfile"

