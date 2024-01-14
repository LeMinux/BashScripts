UID_MIN=1000
UID_MAX=30000

function main {
	if [ "$EUID" -ne 0 ]; then
		echo "This script must be run with sudo."
		exit 1
	fi

	#validation
	randSet="A-Za-z0-9"
	randLength=10
	randString=$(cat /dev/random | tr -dc "$randSet" | fold -w "$randLength" | head -n 1)

	echo -e "THIS WILL LOCK ALL HUMAN USERS!!\nTo validate ensured destruction type this string $randString"
	validate="#"

	while [[ ${validate} != ${randString} ]];
	do
		read -p "Validate here->" validate
	done

	#used getent incase the passwd file is not in /etc/passwd
	#uses a range of UIDs
	#getent passwd | awk -F: ''$UID_MIN' <= $3 && $3 < '$UID_MAX' {system(passwd -l $1)}'
}

main; exit 0
