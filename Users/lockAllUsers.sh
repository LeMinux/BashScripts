#!/bin/bash

#This locks the password of all human users including ones that
#are not directly in /home/
#I did this approach because it is more extensive than ls /home which can miss
#hidden users or users that have changed their base directory away from home

#To exclude users from a password lock a file can be passed in with the
#account names separated by newlines
#EX:
#user1
#user2
#user3

#Keep in mind this is case sensitive

RET_SUCCESS=0
RET_FAILURE=1
UID_BEGIN=1000
PASSWORD_LENGTH=30

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

function generateRandom {
	local randSet="A-Za-z0-9"
	local randLength=$1
	local randString=$(cat /dev/random | tr -dc "$randSet" | fold -w "$randLength" | head -n 1)
	echo "$randString"
}

#The compare functions return success if there is not a match
function compareWithFile {
	local file=$1
	local uid="$2"
	local user="$3"
	if [[ "$uid" -ge "$UID_BEGIN" ]] && [[ "$user" != "nobody" ]] && ! $(grep -q "$user" "$file") ; then
		return $RET_SUCCESS
	else
		return $RET_FAILURE
	fi
}

function compareNoFile {
	local uid="$1"
	local user="$2"
	if [[ "$uid" -ge "$UID_BEGIN" ]] && [[ "$user" != "nobody" ]]; then
		return $RET_SUCCESS
	else
		return $RET_FAILURE
	fi
}

function main {
	if [ "$EUID" -ne 0 ]; then
		echo "This script must be run with sudo."
		exit 1
	fi
	
	cmpBase="compareNoFile"
	if [[ $# -gt 1 ]]; then
		echo "Too many arguments given" >&2
		exit 1
	elif [[ $# -eq 1 ]]; then
		if [ -s "$1" ]; then
			if validFileSyntax "$1"; then
				cmpBase="compareWithFile $1"
			else
				echo "Bad File Entries" >&2
				exit 1
			fi
		else
			echo "Exclusion file does not exist or is empty" >&2
			exit 1
		fi
	fi

	#Warning messages
	local keyString=$(generateRandom 10)
	if [[ $# -eq 0 ]]; then
		echo -e "THIS WILL LOCK THE PASSWORD OF ALL HUMAN USERS!!\nTo validate ensured locking type this string-> $keyString"
	else
		echo -e "THIS WILL LOCK THE PASSWORD OF ALL OUTSIDE THE EXCLUSION FILE!!\nTo validate ensured locking type this string-> $keyString"
	fi

	#validation
	local validate="#"
	while [[ "$validate" != "$keyString" ]];
	do
		read -p "Validate here->" validate
	done

	if [ -f "locked.txt" ]; then
		echo -n "" > locked.txt
	fi

	#used getent incase the passwd file is not in /etc/passwd
	while IFS=: read user x uid dontcare; do
		local cmpCall="$cmpBase "
		cmpCall+="$uid "
		cmpCall+="$user"
		if $cmpCall ; then
			echo "Locked user $user" >> locked.txt
			#passwd -l "$user"
		fi
	done < <(getent passwd)
}

main "$@"; exit 0

