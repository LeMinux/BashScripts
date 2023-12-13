# quick audit script

enbolden=$(tput bold)
normal=$(tput sgr0)
red=$(tput setaf 1)

listSudo=false
listUser=false
listGroup=false
listUserToGroup=false
makeFiles=false

listSudoers(){
	echo -e "$red$enbolded>>List of sudoers<<$normal"
	sudoers=$(sudo cat /etc/sudoers | grep -v '^$\|^\s*#\|^@')
	echo "$sudoers"
	echo "$sudoers" > sudoers.txt
	echo -e "\n"
}

listUsers(){
	echo -e "$red$enbolden>>list of users<<$normal"
	users=$(cat /etc/passwd | cut -d: -f1 | sort)
	#cat /etc/passwd | cut -d: -f1 | sort >> users.txt
	echo "$users"
	echo "$users" > users.txt
	echo -e "\n"
}

listGroups(){
	echo -e "$red$enbolden>>List of groups<<$normal"
	groups=$(cat /etc/group | cut -d: -f1 | sort)
	#cat /etc/group | cut -d: -f1 | sort >> groups.txt
	echo "$groups"
	echo "$groups" > groups.txt
	echo -e "\n"
}

listUserToGroups(){
	echo -e "$red$enbolden>>List of users and their associated groups<<$normal"
	for user in $(cut -d: -f1 /etc/passwd); do
		echo "User: $user $(id $user)"
		echo "--------------------"
	done
}

#no arguments passed so do default action
if [ "$#" == 0 ]; then
	listSudo=true
	listUser=true
	listGroup=true
	listUserToGroup=true
fi

for flag in "$@"; do
	if [ "$flag" == "-s" ]; then
		listSudo=true
	fi

	if [ "$flag" == "-u" ]; then
		listUser=true
	fi

	if [ "$flag" == "-g" ]; then
		listGroup=true
	fi

	if [ "$flag" == "-ug" ]; then
		listUserToGroup=true
	fi

	if [ "$flag" == "-mf" ]; then
		makeFiles=true
	fi
done

if [ "$listSudo" == true ]; then
	listSudoers()
fi

if [ "$listUser" == true ]; then
	listUsers()
fi

if [ "$listGroup" == true ]; then
	listGroups()
fi

if [ "$listUserToGroup" == true ]; then
	listUserToGroups()
fi
