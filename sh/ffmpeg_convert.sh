#Searches provided folder for h264 files and converts them to x265 iPhone and Internet compatible based on target video size and minimum_bitrate

#!/bin/bash
destination_dir="DESTINATION_DIR"
target_video_size_MB="SIZE"
search_dir="SEARCH_DIR"
minimum_bitrate=MINIMUM BITRATE

[ ! -d "$destination_dir" ] && echo "Destination Folder $destination_dir DOES NOT exists." && exit
[ ! -d "$search_dir" ] && echo "Searc Folder $search_dir DOES NOT exists." && exit


for entry in "$search_dir"/*.mp4
do
	origin_video_codec=$(ffprobe -v error -pretty -show_streams -select_streams 0 "$entry" | grep -Po "(?<=^codec_name\=)\w*")
	if [ "$origin_video_codec" == "h264" ]; then
			echo "Codec is h264"
			input_file="$(basename -- $entry)"
			origin_duration_s=$(ffprobe -v error -show_streams -select_streams a "$entry" | grep -Po "(?<=^duration\=)\d*\.\d*")
			origin_audio_bitrate_kbit_s=$(ffprobe -v error -pretty -show_streams -select_streams a "$entry" | grep -Po "(?<=^bit_rate\=)\d*\.\d*")
			origin_video_bitrate=$(ffprobe -v error -pretty -show_streams -select_streams 0  $entry | grep -Po "(?<=^bit_rate\=)\d*\.\d* \w*")
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
			half_origin_bitrate_kbit=$(echo "$origin_bitrate_kbit / 2" | bc -l  | grep -Po "\d*" | head -1)
			
			if [ $minimum_bitrate -lt $origin_bitrate_kbit ]; then 
				echo "Minimum bitrate smaller then origin.. Proceeding"
				##Check if target bitrate is greater then half
				if [ $clean_target_video_bitrate -gt $half_origin_bitrate_kbit ]; then
					echo "Suggested Bit Rate $target_video_bitrate_kbit_s Is More Than Half $half_origin_bitrate_kbit"
					target_video_bitrate_kbit_s=$half_origin_bitrate_kbit
					clean_target_video_bitrate=$(echo $target_video_bitrate_kbit_s | grep -Po "\d*" | head -1)
				fi
				
				##Check if target bitrate is less than minimum
				if [ $clean_target_video_bitrate -lt $minimum_bitrate ]; then
										echo "Bit Rate Too Small .. Original: $clean_target_video_bitrate .. New: $minimum_bitrate"
					target_video_bitrate_kbit_s=$minimum_bitrate
					clean_target_video_bitrate=$(echo $target_video_bitrate_kbit_s | grep -Po "\d*" | head -1)
				fi
				
							echo "File: $input_file"
	#		echo "Size: $(du -sh $entry)"
	#		echo "Original bitrate: $origin_video_bitrate"
	#		echo "New Bitrate: $target_video_bitrate_kbit_s"
	#		echo "Half of Original: $half_origin_bitrate_kbit" 
				ffmpeg -y -i "$entry" -c:v libx265 -b:v "$target_video_bitrate_kbit_s"k -x265-params no-slow-firstpass=1:pass=1 -preset slow -tag:v hvc1 -an -f mp4 /dev/null && \
				ffmpeg -i "$entry" -c:v libx265 -b:v "$target_video_bitrate_kbit_s"k -x265-params pass=2 -preset slow -tag:v hvc1 -c:a copy "${destination_dir}/${input_file}"
			fi
			echo " ";
	fi
done
