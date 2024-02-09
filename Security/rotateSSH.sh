#!/bin/bash

#so far this doesn't actually rotate keys
function main {
	local user=""
	local host=""
	local outfile="$(echo ~)/.ssh/id_"
	local valid="false"
	local selection=""
	local bytes=""
	local curDate="$(date +"%d-%b-%Y")"

	while [[ "$user" == "" ]]; do
		read -p "Enter the host username: " user
	done

	while [[ "$host" == "" ]]; do
		read -p "Enter the host to where you are connecting: " host
	done

	while [[ "$valid" == "false" ]]; do
		echo -e "1) rsa"
		echo -e "2) dsa"
		echo -e "3) ecdsa"
		echo -e "4) ed25519"
		echo -e "5) ecdsa-sk"
		echo -e "6) ed25519-sk"
		read -p "Enter the number for which algorithm to use: " selection

		case "$selection" in
			1)
				valid="true"
				selection="rsa"
				bytes="4096"
			;;

			2)
				valid="true"
				selection="dsa"
			;;

			3)
				valid="true"
				selection="ecdsa"
				bytes="521"
			;;

			4)
				valid="true"
				selection="ed25519"
			;;

			5)
				valid="true"
				selection="ecdsa-sk"
			;;

			6)
				valid="true"
				selection="ed25519-sk"
			;;

			*) echo -e "Not an option";;
		esac
	done

	#to effectively make a do-while loop
	local filenameInput=""
	local confirmName="#"

	echo "Note the keys will be saved in ~/.ssh/ even with renaming"
	while [[ "$filenameInput" != "$confirmName" ]]; do
		read -p "What do you want to name the file (enter nothing to keep it id_<encryption>-(date)): " filenameInput
		read -p "Confirm this is what you want (enter nothing to keep it id_<encryption>-(date)): " confirmName
		echo ""
	done

	if [[ "$filenameInput" == "" ]]; then
		outfile+="$selection"
	else
		outfile+="$filenameInput"
	fi

	outfile+="_$curDate"

	if [[ "$bytes" != "" ]]; then
		ssh-keygen -f "$outfile" -t "$selection" -b "$bytes"
	else
		ssh-keygen -f "$outfile" -t "$selection"
	fi

	#find a way to remove the old authorized_keys/known keys
	#also remove older keys
	#ask to remove older keys?
	ssh-copy-id -i "$outfile" "$user"@"$host"
}

main "$@"; exit 0
