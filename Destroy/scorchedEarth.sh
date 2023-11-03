if [ "$EUID" -ne 0 ]; then
    echo "This script must be run with sudo."
    exit 1
fi

randSet="A-Za-z0-9"
randLength=10
randString=$(cat /dev/random | tr -dc "$randSet" | fold -w "$randLength" | head -n 1)

echo -e "THIS WILL DESTROY EVERYTHING!!\nTo validate ensured destruction type this string $randString"
validate="#"

while [[ ${validate} != ${randString} ]];
do
	read -p "Validate here->" validate
done

#uncomment this to use
#lsblk -a | awk '/\|-/ || /`-/ { system "dd if=/dev/zero of=/dev/"substr($1, 3)}'
