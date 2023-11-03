# quick audit script

enbolden=$(tput bold)
normal=$(tput sgr0)
red=$(tput setaf 1)

echo -e "$red$enbolded>>List of sudoers<<$normal"
sudo cat /etc/sudoers | grep -v '^$\|^\s*#\|^@'

echo -e "\n"

echo -e "$red$enbolden>>list of users<<$normal"
cat /etc/passwd | cut -d: -f1 | sort
cat /etc/passwd | cut -d: -f1 | sort >> users.txt

echo -e "\n"

echo -e "$red$enbolden>>List of groups<<$normal"
cat /etc/group | cut -d: -f1 | sort 
cat /etc/group | cut -d: -f1 | sort >> groups.txt

echo -e "\n"

echo -e "$red$enbolden>>List of users and their associated groups<<$normal"
for user in $(cut -d: -f1 /etc/passwd); do
	echo "User: $user $(id $user)"
	echo "--------------------"
done

