#!/bin/bash

#convert1080p.sh
#
# This script takes a mkv container file and output a mkv compressed to a specific quality.
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
	echo "Usage: convert1080p.sh -i {input.mkv} -o {output.mkv} -a {main audio track number} [-s {main subtitle track number}] [-fs {subtitle track to be burned in}]"
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
	-s|--subtitle)
		readonly subtitletrack="$2"
		shift # position arguments to next
		shift
		;;
	-fs|--forcedsubtitle)
		readonly forcedsubtitletrack="$2"
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
	video_options="--encoder x264 --encoder-preset veryslow --encoder-profile high --encoder-level 3.1 --vb $bitrate -2 --pfr"
	#video_options="--encoder x264 --encoder-preset veryslow --encoder-profile High --encoder-level 3.1 -q 16 -2 --pfr"

elif (($videoheight < 1090)); then
	autoselection+="B"
	video_options=" --encoder x264 --encoder-preset VerySlow --encoder-profile high --encoder-level 4.0 -q 20 -2 --pfr"

else
	autoselection+="4"
	#I'm debating of implementing AV1 here since 4k movies are soooo large
	video_options="--encoder x264 --encoder-preset veryslow --encoder-profile High --encoder-level 4.0 -q 20 -2 --pfr"
fi

encoder_options="ref=5:bframes=5 " # Taken from superHQ profile
picture_options="--auto-anamorphic" #--crop auto is default --modulus 2 is default
filters_options="" #profile is all default
subtitles_options=""

## Determine Audio Channel and apply appropriate audio options
audiostream=$(grep -P '(?<=Audio).*[0-9]\.[0-9]' <<< "$scanresults")
IFS=$'\n'
audiochannels=(${audiostream//\\n/ })
audiochannel="${audiochannels[$audiotrack-1]}"
IFS=$OIFS
if [[ $audiochannel == *"7.1"* ]]; then
	autoselection+="7"
	audio_options="-a $audiotrack,$audiotrack,$audiotrack --aencode av_aac,ac3,copy -6 stereo,5point1 -A Stereo,\"Surround 5.1\",\"Surround 7.1\" "

elif [[ $audiochannel == *"5.1"* ]]; then
	autoselection+="5"
	audio_options="-a $audiotrack,$audiotrack -E ca_aac,copy -6 stereo -A Stereo,\"Surround 5.1\" "
else
	autoselection+="2"
	audio_options="-a $audiotrack --aencode copy -A Stereo "
fi

if [ "$subtitletrack" ]; then
	autoselection+="S"
	subtitles_options="-s $subtitletrack" #expecting a string like "1,1,2"
fi
if [ "$forcedsubtitletrack" ]; then
	autoselection+="F"
	subtitles_options="$subtitles_options --subtitle_burned $forcedsubtitletrack" #expecting a string like "2"
fi

## Manual Handbrake Options Override
if false; then
	autoselection="O"
	bitrate="4000"
	video_options="--encoder x264 --x264-preset veryslow --x264-profile high -q 20 -2 --pfr"
	# encoder_options="vbv-maxrate=25000:vbv-bufsize=31250:ratetol=inf" #dev
	audio_options="-a $audiotrack,$audiotrack --aencoder av_aac,copy -6 stereo -A Stereo,\"Surround 5.1\" "
fi

## Encode Video
time "HandBrakeCLI" $video_options --encopts $encoder_options $audio_options $subtitles_options --input "$inputfile" --output "$outputfile" 2>&1
echo "$autoselection"
echo "$handbrakeopt"

