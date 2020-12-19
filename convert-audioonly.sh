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
	echo "Usage: convert-audioonly.sh -i {input.mkv} -o {output.mkv} -a {main audio track number} [-a7 {7 channel audio}] [-a5 {5 channel audio}] | [-a2 {2 channel audio}]"
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
	*)
		except "Unknown input $1"
		shift
		;;
esac
done


## lbhalbhalbha


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
if [ ! "$audiotrack" ]; then
	except "Missing audio track"
fi

autoselection=""
## Determine Video Size and apply appropriate video option
scanresults=$(HandBrakeCLI --input "$inputfile" --scan 2>&1)
videostream=$(grep -P '(?<=Stream).*[0-9]+x[0-9]+' <<< "$scanresults")
videoheight=0
while IFS= read -r line
do
	height=$(grep -oP -m 1 '(?<=[0-9]{3}x)[0-9]+' <<< "$line")
	if [ -z "$height" ]; then
		echo "$height is empty"
	elif (($height > $videoheight)); then
		videoheight=$height
	fi
done <<< "$videostream"
if (($videoheight < 484)); then
	autoselection+="D"
	bitrate="4000"
	video_options="--encoder x264 --encoder-preset VerySlow --encoder-profile high --encoder-level 3.1 --vb $bitrate -2 --pfr"
elif (($videoheight < 1090)); then
	autoselection+="B"
	video_options="--encoder x264 --encoder-preset VerySlow --encoder-profile high --encoder-level 4.0 -q 20 -2 --pfr"
else
	autoselection+="4"
	#I'm debating of implementing AV1 here since 4k movies are soooo large
	video_options="--encoder x264 --encoder-preset VerySlow --encoder-profile high --encoder-level 4.0 -q 20 -2 --pfr"
fi

encoder_options="ref=5:bframes=5:level=4.0:b-adapt=2:direct=auto:analyse=all:me=umh:merange=24:subme=10:trellis=2:vbv-bufsize=31250:vbv-maxrate=25000:rc-lookahead=60 " # Taken from superHQ profile
picture_options="--auto-anamorphic" #--crop auto is default --modulus 2 is default
filters_options="" #profile is all default
subtitles_options=""

## Determine Audio Channel and apply appropriate audio options
if [ "$b75s" ]; then
	audio_options="--audio $ch5track,$ch5track,$ch7track --aencoder av_aac,copy,copy --mixdown stereo --aname Stereo,\"Surround 5.1\",\"Surround 7.1\""
	
else
	audiostream=$(grep -P '(?<=Audio).*[0-9]\.[0-9]' <<< "$scanresults")
	IFS=$'\n'
	audiochannels=(${audiostream//\\n/ })
	audiochannel="${audiochannels[$audiotrack-1]}"
	IFS=$OIFS
	if [[ $audiochannel == *"7.1"* ]]; then
		autoselection+="7"
		audio_options="--audio $audiotrack,$audiotrack,$audiotrack --aencoder av_aac,ac3,copy --mixdown stereo,5point1 --aname Stereo,\"Surround 5.1\",\"Surround 7.1\""
	elif [[ $audiochannel == *"5.1"* ]]; then
		autoselection+="5"
		audio_options="--audio $audiotrack,$audiotrack --aencoder ca_aac,copy --mixdown stereo --aname Stereo,\"Surround 5.1\""
	else
		autoselection+="2"
		audio_options="--audio $audiotrack --aencode copy --aname Stereo"
	fi
fi
## Add Subtitles
if [ "$forcedsubtitletrack" ]; then
	if [ "$subtitletrack" ]; then
		autoselection+="SF"
		subtitles_options="--subtitle $forcedsubtitletrack,$subtitletrack --subtitle-burned" #--subtitle-burned=1 is silent default
	else
		autoselection+="F"
		subtitles_options="--subtitle $forcedsubtitletrack --subtitle-burned"
	fi
elif [ "$subtitletrack" ]; then
	autoselection+="S"
	subtitles_options="--subtitle $subtitletrack" #expecting a string like "1"
fi
if [ "b75s" ]; then
	autoselection=$b75s
fi
## Manual Handbrake Options Override
if false; then
	autoselection="O"
	bitrate="4000"
	video_options="--encoder x264 --x264-preset veryslow --x264-profile high -q 20 -2 --pfr"
	# encoder_options="vbv-maxrate=25000:vbv-bufsize=31250:ratetol=inf" #dev
	audio_options="--audio $audiotrack,$audiotrack --aencoder av_aac,copy --mixdown stereo --aname Stereo,\"Surround 5.1\""
fi

## Encode Video
time "HandBrakeCLI" $video_options --encopts $encoder_options $audio_options $subtitles_options --input "$inputfile" --output "$outputfile" 2>&1
echo "HandBrakeCLI" $video_options --encopts $encoder_options $audio_options $subtitles_options --input "$inputfile" --output "$outputfile"
echo "$autoselection"

