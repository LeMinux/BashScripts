new_dir="./ConvertedVideos"

function convertVideo {
	local file=$1
	local remove_path="${file##*/}"
	local base_file=${remove_path%.*}
	ffmpeg -i "$file" -acodec libmp3lame -q:a 0 -id3v2_version 3 -map 0:a:0 -map 0:v:0 "$new_dir/$base_file.mp3"
}

function readDir {
	local dir=$1

	for item in "$dir"/*; do
		if [[ -f "$item" ]] && [[ "$item" == *.mp4 ]]; then
			convertVideo "$item"
		elif [[ -d "$item" ]]; then
			readDir "$item"
		fi
	done
}

function processEntry {
	local entry=$1

	if [[ -f "$entry" ]] && [[ "$entry" == *.mp4 ]]; then
		convertVideo "$path"
	elif [[ -d "$path" ]]; then
		readDir "$path"
	else
		echo "$entry does not exist"
	fi
}

function main {
	if [[ $# -eq 0 ]]; then
		echo "Usage: $0 <path_to_file_or_directory> [<path_to_more_files_or_directories> ...]"
		exit 1
	fi

	mkdir -p "$new_dir"

	for path in "$@"; do
		processEntry "$path"
	done
}

main "$@"
