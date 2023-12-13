#COMPLETED
#take a command line argument for user files
#Format will be <user>|<group>
#Make groups if it doesn't exist
#Check the sudoers file for who is given root access and ask user to confirm
#Check if user exists
#Verify if | and : need to be defined a certain way
#make function for main

#TODO
#check if define -p does actually matter for checkGroup
#code smarter and have main do checks before creating user. I.E. make create user simply accept the params and have main split before hand.
#If all users are given sudo then prompting the user for sudo permission of specified users should not happen
#user input of a single user

#CONTINUOUS
#conduct a test on a VM

PRINT_NORMAL=$(tput sgr0)
PRINT_RED=$(tput setaf 1)
PRINT_GREEN=$(tput setaf 2)
LOG_FILE="Not_Created.txt"
LOG_AVAILABLE=0

#technically 0 is true and non-zero is false
#however success and failure are more correct terminology
RET_SUCCESS=0
RET_FAILURE=1

#log codes. Predefined codes so passing a string is only necessary if it's not known
MSG_CUSTOM=-1
MSG_NOT_ROOT=1
MSG_ALREADY_EXISTS=2

function printToLog {
	local logFile=$1
	local entry=$2
	local logCode=$3

	LOG_AVAILABLE=1
	case $logCode in
		1) echo "Entry \"$entry\" not created. REASON: User had sudo permissions but shouldn't." >> "$LOG_FILE" ;;
		2) echo "Entry \"$entry\" not created. REASON: User already exists." >> "$LOG_FILE" ;;
		*) echo "Entry \"$entry\" not created. REASON: $4." >> "$LOG_FILE"
	esac
}

#randomly generates a password of 20 characters
function generatePassword {
	local randSet='A-Za-z0-9!\"#$%&'\''()*+,-./:;<=>?@[\]^_`{|}~'
	local randLength=20
	local randString=$(cat /dev/random | tr -dc "$randSet" | fold -w "$randLength" | head -n 1)
	echo "$randString"
}

#check if user or grouphas sudo permission
#returns true if there is sudo permission false otherwise
function hasSudoPermission {
	for userOrGroup in "$@"; do
		echo "Checking root status of $userOrGroup"
		if [[ "$userOrGroup" != "" ]]; then
			if [[ "$(awk '!/^#/ && /'"$userOrGroup"'/ ' /etc/sudoers)" != "" ]]; then
				return $RET_SUCCESS
			fi
		fi
	done
	return $RET_FAILURE
}

#check if a group exists and if not it will create it
function checkGroup {
	local groupString
	groupString=$1

	readarray -td '' groupArray < <(awk '{ gsub(/,/,"\0"); print; }' <<<"$groupString, "); unset 'a[-1]';
	declare -p groupArray;
	#check if each group exists
	for element in ${groupArray[@]}; do
		if [[ $(awk '/'"$element:"'/' /etc/group) == "" ]]; then
			groupadd "$element"
			echo "Group \"$element\" does not exist making it"
		fi
	done
}

#check if user is already created
#returns true if user does exist false otherwise
function userExists {
	local user=$1
	echo "user exists?-> $(awk '/'"$user"':/' /etc/passwd)"
	if [[ $(awk '/'"$user"':/' /etc/passwd) == "" ]]; then
		return $RET_FAILURE
	else
		return $RET_SUCCESS
	fi
}

#simply get a direct yes or no from the user
function getYesNo {
	local message
	message=$1

	while true; do
		read -rp "$message (yes/no): " response
		case "$response" in
			[Yy]|[Yy][Ee][Ss]) return $RET_SUCCESS ;;
			[Nn]|[Nn][Oo]) return $RET_FAILURE ;;
			*) echo "Please enter 'yes' or 'no'" ;;
		esac
	done </dev/tty
	#have to redirect the terminal in because it was extracting empty strings
	#preventing the user from ever inputting in the first place
}

#accepts the entire user entry line as a parameter
function createUser {
	local userName
	userName=$1

	local primaryGroup
	primaryGroup=$2

	local secondaryGroup
	secondaryGroup=$3

	local password
	password=$(generatePassword)

	#build command
	local creationString
	creationString="useradd -m -p $(openssl passwd -6 $password)"

	#build sudo checks
	local rootCheck
	rootCheck="$userName"

	#build output to user
	local verbosity
	verbosity="${PRINT_GREEN}Created user $userName"

	if [[ "$primaryGroup" != "" ]];then
		checkGroup "$primaryGroup"
		creationString+=" -g $primaryGroup"
		rootCheck+=" $primaryGroup"
		verbosity+=" and added them to the primary group \"$primaryGroup\""
	fi

	#replaces commas with spaces
	if [[ "$secondaryGroup" != "" ]];then
		checkGroup "$secondaryGroup"
		creationString+=" -G $secondaryGroup"
		rootCheck+=" ${secondaryGroup//,/ }"
		verbosity+=" and secondary group(s) \"$secondaryGroup\""
	fi

	creationString+=" $userName"
	verbosity+="${PRINT_NORMAL}"

	#doesn't use double quotes so it is not considered one string to $@
	if hasSudoPermission $rootCheck; then
		echo -e "${PRINT_RED}Warning:${PRINT_NORMAL}"
		if getYesNo "The user \"$userName\" will be given sudo permissions. Is this correct?"; then
			$creationString
			echo "$verbosity"
			echo "Random password for user \"$userName\" is -> $password"
			echo ""
		else
			printToLog "$LOG_FILE" "$entry" $MSG_NOT_ROOT
		fi
	else
		$creationString
		echo "$verbosity"
		echo "Random password for user \"$userName\" is -> $password"
		echo ""
	fi
}

#this scans the file given to make sure its syntax is correct
#this way all users can be added at once
#Check if swapping | and : breaks functionality
function validFileSyntax {
	local inFile=$1
	local exitCode
	exitCode=$RET_SUCCESS
	declare -i lineNum=1

	while IFS= read -r entry; do
		local errorMessage=""
		local badLine="false"
		local hasPipe="false"
		local hasColon="false"

		#if not an empty line
		if [[ "$entry" != "" ]]; then
			if [[ "$entry" != *"|"* ]]; then
				errorMessage+="Missing group delimiter '|'\n"
				exitCode=$RET_FAILURE
				badLine="true"
			else
				hasPipe="true"
				userName=${entry%|*}
				if [[ "$userName" == "" ]]; then
					errorMessage+="Missing entry for username\n"
					exitCode=$RET_FAILURE
					badLine="true"
				fi
			fi

			if [[ "$entry" != *":"* ]]; then
				errorMessage+="Missing secondary group delimiter ':'\n"
				exitCode=$RET_FAILURE
				badLine="true"
			else
				hasColon="true"
				secGroup=${entry##*:}
				if [[ "$secGroup" == *" "* ]]; then
					errorMessage+="Secondary group list must not contain any whitespace\n"
					exitCode=$RET_FAILURE
					badLine="true"
				fi
			fi

			#if has both pipe and colon check if they have the correct position
			if [[ "$hasPipe" == "true" ]] && [[ "$hasColon" == "true" ]]; then
				local pipe="${entry%%"|"*}"
				local colon="${entry%%":"*}"
				if [[ ${#pipe} -gt ${#colon} ]]; then
					errorMessage+="The group delimiter must precede the secondary group delimiter\n"
					exitCode=$RET_FAILURE
					badLine="true"
				fi
			fi

			if [[ "$badLine" == "true" ]]; then
				echo "${PRINT_RED}Invalid entry while parsing at line $lineNum${PRINT_NORMAL} -> \"$entry\""
				echo -e "$errorMessage"
			fi
		fi
		lineNum+=1
	done <$inFile
	return $exitCode
}

#main
function main {
	if [ "$EUID" -ne 0 ]; then
		echo "This script must be run with sudo."
		exit 1
	fi

	#reset not created file or create it
	if [ -f "$LOG_FILE" ]; then
		local filesize=$(stat -c %s "Not_Created.txt")
		if [[ filesize -ge 0 ]]; then
			printf '' > "$LOG_FILE"
		fi
	else
		touch "$LOG_FILE"
	fi

	#checks if everyone will be given sudo permission and if this is dangerously wanted
	if [[ $(awk '!/^#/ && $1 == "ALL"' /etc/sudoers) != "" ]]; then
		echo -e "${PRINT_RED}WARNING: ALL USERS ARE GIVEN ROOT PERMISSIONS!${PRINT_NORMAL}"

		if getYesNo "Are you sure you want this?"; then
			echo "Procced at your own risk"
		else
			echo "Remove or comment the line that begins with ALL"
			exit 1
		fi
	fi

	#make one user
	if [[ "$#" -eq 0 ]]; then
		local uName=""
		local groupName=""
		local secondaryGroups=""

		echo "~~No file given so this will only prompt for one user creation~~"
		while [[ "$uName" == "" ]]; do
			read -p "Enter the name of the user account -> " uName
		done

		#check if user exists

		if getYesNo "Is this user associated with any primary groups?"; then
			echo "is yes"
		else
			echo "is no"
		fi

		if getYesNo "Is this user associated with any secondary groups?"; then
			echo "yeppy yes"
		else
			echo "noppy no"
		fi

		#check sudo permissions

		#TODO user input
	elif [[ "$#" -eq 1 ]]; then
		local file=$1
		if validFileSyntax "$file"; then
			while IFS= read -r entry; do
				if [[ "$entry" != "" ]]; then
					echo "$entry"
					local userName
					userName=${entry%|*}

					if userExists "$userName"; then
						printToLog "$LOG_FILE" "$entry" $MSG_ALREADY_EXISTS
					else
						local primGroup
						primGroup=${entry%%:*}
						primGroup=${primGroup##*|}

						local secGroup
						secGroup=${entry##*:}
						createUser "$userName" "$primGroup" "$secGroup"
					fi
				fi
			done <$file
		fi

		#only print logs if it was written to
		if [[ $LOG_AVAILABLE -eq 1 ]]; then
			echo -e "Users listed that were not created\n|\nv"
			cat $LOG_FILE
		fi
	else
		echo "Too many arguments given"
	fi
}

#initiate execution
main "$@"; exit 0
