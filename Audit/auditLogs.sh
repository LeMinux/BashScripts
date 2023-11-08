AUTHLOG="/var/log/auth.log"
SYSLOG="/var/log/syslog"
APTLOG="/var/log/apt/history.log"
OUTPUT_DIR="Audits"
#Test on an Ubuntu box
#What logs to check in


#prints out throughPut to stdout
verbose_print(){
	local throughPut="$1"
	local outFile="$2"
	echo -e "$throughPut\n"
	echo -e "$throughPut\n" > $outFile
}

#places throughPut into file
regular_print(){
	local throughPut="$1"
	local outFile="$2"
	echo -e "$throughPut\n" > $outFile
}


#create output directory if it does not exist
if [ ! -d "$OUTPUT_DIR" ]; then
	mkdir -p "$OUTPUT_DIR"
fi

verbose=false
for flag in "$@"; do
	if [ "$flag" == "-v" ]; then
		verbose=true
	fi
done

#sets print function based on verbosity
printFunction=regular_print
if [ "$verbose" == true ]; then
	printFunction=verbose_print
fi


#audits for root actions and attempts
$printFunction "$(grep "/usr/bin/su" $AUTHLOG)" "$OUTPUT_DIR/su.txt"
$printFunction "$(grep "incorrect password attempt" $AUTHLOG)" "$OUTPUT_DIR/incorrects.txt"
$printFunction "$(grep "USER=root" $AUTHLOG)" "$OUTPUT_DIR/roots.txt"


#audits services
$printFunction "$(grep "Closed" $SYSLOG)" "$OUTPUT_DIR/closed.txt"
$printFunction "$(grep "Stopped" $SYSLOG)" "$OUTPUT_DIR/stopped.txt"

#audits apt
$printFunction "$(grep -B 3 -A 1 "apt remove" $APTLOG)" "$OUTPUT_DIR/removed.txt"
$printFunction "$(grep -B 3 -A 1 "apt purge" $APTLOG)" "$OUTPUT_DIR/purged.txt"
$printFunction "$(grep -B 3 -A 1 "apt install" $APTLOG)" "$OUTPUT_DIR/installed.txt"
