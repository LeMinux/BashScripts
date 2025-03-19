new_dir="./AddedGenre/"
genre=""

function convertVideo {
	local file=$1
	local remove_path="${file##*/}"
	local base_file=${remove_path%.*}
	ffmpeg -i "$file" -metadata genre="$genre" -codec copy "$new_dir/$base_file.mp3"
}

function readDir {
	local dir=$1

	for item in "$dir"/*; do
		if [[ -f "$item" ]] && [[ "$item" == *.mp3 ]]; then
			convertVideo "$item"
		elif [[ -d "$item" ]]; then
			readDir "$item"
		fi
	done
}

function processEntry {
	local entry=$1

	if [[ -f "$entry" ]] && [[ "$entry" == *.mp3 ]]; then
		convertVideo "$path"
	elif [[ -d "$path" ]]; then
		readDir "$path"
	else
		echo "$entry does not exist"
	fi
}

function main {
	if [[ $# -le 1 ]]; then
		echo "Usage: $0 <genre> <path_to_file_or_directory> [<path_to_more_files_or_directories> ...]"
		exit 1
	fi

	mkdir -p "$new_dir"

	genre="$1"
	shift
	for path in "$@"; do
		processEntry "$path"
	done
}

main "$@"
