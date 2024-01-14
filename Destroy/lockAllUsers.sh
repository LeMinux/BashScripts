#this script is a mild destruction

function main {
	uid_min=1000
	uid_max=30000
	uid_restrict=1000

	if [ "$EUID" -ne 0 ]; then
		echo "This script must be run with sudo."
		exit 1
	fi

	#validation
	randSet="A-Za-z0-9"
	randLength=10
	randString=$(cat /dev/random | tr -dc "$randSet" | fold -w "$randLength" | head -n 1)

	echo -e "THIS WILL LOCK ALL HUMAN USERS!!\nTo validate ensured locking type this string-> $randString"
	validate="#"

	while [[ ${validate} != ${randString} ]];
	do
		read -p "Validate here->" validate
	done

	#used getent incase the passwd file is not in /etc/passwd
	#uses a range of UIDs
	getent passwd | awk -F: ''$uid_min' <= $3 && $3 < '$uid_max' && $3 != '$uid_restrict' {system("echo locking " $1 " && passwd -l " $1)}'
}

main; exit 0
