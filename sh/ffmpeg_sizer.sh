#Searches provided dir for h264 files and returns what the suggested bitrate would be based off the target size and minimum bitrate

#!/bin/bash
target_video_size_MB="SIZE"
search_dir="SEARCH_DIR"
minimum_bitrate=1800

[ ! -d "$search_dir" ] && echo "Search Folder $search_dir DOES NOT exists." && exit


for entry in "$search_dir"/*.mp4
do
	origin_video_codec=$(ffprobe -v error -pretty -show_streams -select_streams 0 "$entry" | grep -Po "(?<=^codec_name\=)\w*")
	if [ "$origin_video_codec" == "h264" ]; then
			echo "Codec is h264"
			input_file="$(basename -- $entry)"
			origin_duration_s=$(ffprobe -v error -show_streams -select_streams a "$entry" | grep -Po "(?<=^duration\=)\d*\.\d*")
			origin_audio_bitrate_kbit_s=$(ffprobe -v error -pretty -show_streams -select_streams a "$entry" | grep -Po "(?<=^bit_rate\=)\d*\.\d*")
			origin_video_bitrate=$(ffprobe -v error -pretty -show_streams -select_streams 0 $entry | grep -Po "(?<=^bit_rate\=)\d*\.\d* \w*")
			target_audio_bitrate_kbit_s=$origin_audio_bitrate_kbit_s # TODO for now, make audio bitrate the same
			target_video_bitrate_kbit_s=$(\
					awk \
					-v size="$target_video_size_MB" \
					-v duration="$origin_duration_s" \
					-v audio_rate="$target_audio_bitrate_kbit_s" \
					'BEGIN { print  ( ( size * 8192.0 ) / ( 1.048576 * duration ) - audio_rate ) }')
			clean_target_video_bitrate=$(echo $target_video_bitrate_kbit_s | grep -Po "\d*" | head -1)
			origin_bit=$(echo $origin_video_bitrate | grep -Po "\d*.\d*" | head -1 )
			echo "Suggested Bitrate: $target_video_bitrate_kbit_s"
			origin_bitrate_kbit=$(echo "$origin_bit * 1000" | bc -l | grep -Po "\d*" | head -1)
			if [ $clean_target_video_bitrate -lt $minimum_bitrate ]; then
					echo "Suggested Bit Rate Too Small"
					target_video_bitrate_kbit_s=$minimum_bitrate
			fi
			half_origin_bitrate_kbit=$(echo "$origin_bitrate_kbit / 2" | bc -l  | grep -Po "\d*" | head -1)
			if [ $target_video_bitrate_kbit_s -gt $half_origin_bitrate_kbit ]; then
					echo "Suggested Bit Rate $target_video_bitrate_kbit_s Is More Than Half $half_origin_bitrate_kbit"
					target_video_bitrate_kbit_s=$half_origin_bitrate_kbit
			fi
			echo "File: $input_file"
			echo "Size: $(du -sh $entry)"
			echo "Original bitrate: $origin_video_bitrate"
			echo "New Bitrate: $target_video_bitrate_kbit_s"
			
	fi
done
