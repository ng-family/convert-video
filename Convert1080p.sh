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

## Parse arguments
case $1 in
	-h|--help)
	echo "Usage: convert1080p.sh -i {input.mkv} -o {output.mkv} -s {main subtitle track number}"
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
if [ ! "$audiotrack" ]; then
	except "Missing audio track"
fi

## Handbrake Options for 1080
video_options="--encoder x264 --encoder-preset VerySlow --encoder-profile High --encoder-level 4.0 -q 20 -2 --pfr"
encoder_options="ref=5:bframes=5" # Taken from superHQ profile
# encoder_options="vbv-maxrate=25000:vbv-bufsize=31250:ratetol=inf" #dev
audio_options="-a "$audiotrack" -E av_aac,ac3,copy:dtshd -6 stereo,5point1 -A \"Stereo,AC3\ Surround\ 5.1,Surround\ 5.1\""
picture_options="--auto-anamorphic" #--crop auto is default --modulus 2 is default
filters_options="" #profile is all default
subtitles_options=""
if [ "$subtitletrack" ]; then
	subtitles_options="-s "$subtitletrack"" #expecting a string like "1,1,2"
fi
if [ "$forcedsubtitletrack" ]; then
	subtitles_options=""$subtitles_options" --subtitle_burned "$forcedsubtitletrack"" #expecting a string like "2"
fi

## Encode Video
time HandBrakeCLI "$video_options" --encopts "$encoder_options" "$audio_options" "$subtitles_options" --input "$inputfile" --output "$outputfile" 2>&1

