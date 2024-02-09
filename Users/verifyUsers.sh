#!/bin/bash

#This is a bash script that will remove any users that do not match
#the entries in the given file. This will also check users that do
#not have a home directory folder.

#Entries in the given file should just be the account's name separated by newlines
#EX:
#user1
#user2
#user3

#Keep in mind this is case sensitive

RET_SUCCESS=0
RET_FAILURE=1

function validFileSyntax {
	local inFile=$1
	local goodFile=$RET_SUCCESS

	declare -i lineNum=1

	while IFS= read -r entry; do
		#if not an empty line
		if [[ "$entry" != "" ]]; then
			if [[ "$entry" == *" "* ]]; then
				echo -e "Line $lineNum has multiple entries"
				goodFile=$RET_FAILURE
			fi

		fi
		lineNum+=1
	done <$inFile

	return $goodFile
}

function main {
	if [[ $# -eq 0 ]]; then
		echo "User file is not given" >&2
		exit 1
	fi

	if [[ $# -ge 2 ]]; then
		echo "Too many arguments given. The only argument should be a file" >&2
		exit 1
	fi

	if ! [ -f "$1" ]; then
		echo "File given does not exist" >&2
		exit 1
	fi

	if ! [ -s "$1" ]; then
		echo "File given is empty" >&2
		exit 1
	fi

	if ! validFileSyntax "$1" ; then
		echo "Bad file entries" >&2
		exit 1
	fi

	local userfile="$1"
	local MIN_USER_ID=1000

	while IFS=: read user x uid dontcare; do
		if [[ "$uid" -ge "$MIN_USER_ID" ]] && ! grep -q "$user" "$userfile" && [[ "$user" != "nobody" ]]; then
			echo "Removing user $user"
			#userdel -f "$user"
		fi
	done < <(getent passwd)
}

main "$@"; exit 0
