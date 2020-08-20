#!/bin/bash

#convert1080p.sh
#
# This script takes a mkv container file and output a mkv compressed to a specific quality.
# 
# TO DO:
# Allow arguments to pass audio and subtitle selections to use.  Main English audio, subtitles, and forced subtitles.

# handbrake_options="--markers --large-file --encoder x264 --encopts vbv-maxrate=25000:vbv-bufsize=31250:ratetol=inf --crop 0:0:0:0 --strict-anamorphic"

except() {
	echo "Error: $1" >&2
	exit ${2:-1}
}

case $1 in
    --help)
	echo "Usage: convert1080p.sh {input.mkv} {output.mkv}"
	;;
esac

readonly inputfile="$1"
readonly outputfile="$2"

if [ ! "$inputfile" ]; then
	except "Missing source file"
fi


if [ ! "$outputfile" ]; then
	except "Missing required output"
fi

video_options="-encoder x264 --encoder-preset VerySlow --encoder-profile High --encoder-level 4.0 -q 20 -2 --pfr"
encoder_options="ref=5:bframes=5" # Taken from superHQ profile
# encoder_options="vbv-maxrate=25000:vbv-bufsize=31250:ratetol=inf" #dev
audio_options='-aencoder av_aac,ac3,copy:dtshd --mixdown "stereo,5point1" --aname "Stereo,AC3 Surround 5.1,Surround 5.1"'
picture_options="--auto-anamorphic" #--crop auto is default --modulus 2 is default
filters_options="" #profile is all default
subtitles_options="-s 1" #-s 1,2,3 --subtitle_burned 2

time HandBrakeCLI $video_options --encopts $encoder_options $audio_options $subtitles_options --input $inputfile --output $outputfile 2>&1

#HandBrakeCLI -encoder x264 --encoder-preset VerySlow --encoder-profile High --encoder-level 4.0 -x ref=5:bframes=5 -q 20 -2 --pfr -E av_aac,ac3,copy:dtshd -6 "stereo,5point1" -A "Stereo,AC3 Surround 5.1,Surround 5.1" -s 1 -i THE\ SPY\ WHO\ LOVED\ ME_t00.mkv -o The.mkv