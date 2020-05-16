#!/bin/bash
#!/bin/bash
#
# Script to start openvpn
# Run as cron job regularly
# Checks whether tun* interface is up, and if not, starts openvpn
#   with custom configuration
# Set variables below for custom configuration
#
# Example usage:
#  ./connect.sh
#  ./connect.sh "AU Sydney"
#  ./connect.sh --log
#  ./connect.sh --port-forward
#  ./connect.sh --kill
#

# full path to openvpn
OPENVPN=/usr/sbin/openvpn

# .ovpn files are stored in this directory
OPENVPN_CONFIG_DIR=/home/vpn/vpn-config/ovpn

# default config file, without .ovpn extension
OPENVPN_CONFIG_DEFAULT="AU Sydney"

# auth credentials, 1st line = username, 2nd line = password
OPENVPN_CREDENTIALS=/home/vpn/vpn-config/credentials.txt

# log file
OPENVPN_LOG=/var/log/openvpn.log

# custom options
OPENVPN_CUSTOM="--keepalive 5 30 --mute-replay-warnings --auth-retry none --verb 4 --writepid /var/run/openvpn.pid --resolv-retry 3 --persist-remote-ip --remap-usr1 SIGTERM"

# check if command exists, if not then exit 1
function check_command() {
    command -v $1 &> /dev/null || { echo >&2 "$1 not found"; exit 1; }
}

# check if this script is invoked from within cron
function is_cron() {
    service=$(loginctl show-session $(</proc/self/sessionid) | sed -n '/^Service=/s/.*=//p')
    if [ "$service" = "crond" ]; then
        return 0
    else
        return 1
    fi
}

# start openvpn in daemon mode
function restart_openvpn() {
  echo "Running OpenVPN config \"$OPENVPN_CONFIG_DIR/${CONFIG}.ovpn\""
  $OPENVPN \
      $OPENVPN_CUSTOM \
      --daemon \
      --log-append "$OPENVPN_LOG" \
      --auth-user-pass "$OPENVPN_CREDENTIALS" \
      --cd "$OPENVPN_CONFIG_DIR" \
      --config "${OPENVPN_CONFIG_DIR}/${CONFIG}.ovpn"
}

function kill_openvpn() {
	# extract pid
	pid=$(pgrep -x "openvpn")

	if [ $? -ne 0 ]; then
		echo "No openvpn process running" >&2
		exit 1
	fi

	# Attempt to kill process
	kill -s SIGTERM $pid

	# Give some time for it to be killed, 1s should be enough, adjust as needed
	sleep 1

	# Check if process is killed
	pgrep -x "openvpn"
	if [ $? -eq 0 ]; then
		# process still exists (may or may not be the same!)
		echo "Process was not killed. Perhaps try again?"
		exit 1;
	else
		# success
		exit 0
	fi
}

# check dependent commands
check_command pgrep
check_command "$OPENVPN"

# check for config dir
test -d "$OPENVPN_CONFIG_DIR" &> /dev/null || { echo "Directory '$OPENVPN_CONFIG_DIR' not found" >&2; exit 1; }

# check for credentials file
test -f "$OPENVPN_CREDENTIALS" &> /dev/null || { echo "Credentials file '$OPENVPN_CREDENTIALS' not found" >&2; exit 1; }

# Remove 'auth-user-pass' lines from all ovpn/*.ovpn files
# There's a possibility this line is deleting all lines from the files, not sure why!
sed -i '/^auth-user-pass/d' ovpn/*.ovpn

# check if we are manually routing
# ** no longer used **
if [ ! -z ${OPENVPN_MANUAL_ROUTE+x} ]; then
    echo "Manual routing enabled..."
    # check if --up script exists
    test -f "$OPENVPN_UP" &> /dev/null || { echo "Up script '$OPENVPN_UP' not found" >&2; exit 1; }
    OPENVPN_CUSTOM="$OPENVPN_CUSTOM --route-noexec --script-security 2 --up \"$OPENVPN_UP\" --route remote_host 255.255.255.255 net_gateway"
fi

# parse script arguments
if [ $# -eq 0 ]; then
    # default config .ovpn file to use (do not include the .ovpn extension)
    CONFIG=$OPENVPN_CONFIG_DEFAULT
elif [ "$1" == "--log" ]; then
    # display log file
    tail -f "$OPENVPN_LOG"
    exit 0
elif [ "$1" == "--portforward" ]; then
    # for Private Internet Access VPN only
    # get port forward assignment - displays json output from PIA
    check_command wget
    echo "Checking for forwarded port..."
    client_id=$(head -n 100 /dev/urandom | md5sum | tr -d " -")
    local_ip=$(ifconfig tun0 | grep "inet" | tr -s ' ' | cut -d ' ' -f 3)
    user=$(sed '1q;d' $OPENVPN_CREDENTIALS)
    password=$(sed '2q;d' $OPENVPN_CREDENTIALS)
    wget -q --post-data="user=$user&pass=$password&client_id=$client_id&local_ip=$local_ip" -O - 'https://www.privateinternetaccess.com/vpninfo/port_forward_assignment'
    echo ""
    exit 0
elif [ "$1" == "--kill" ]; then
    kill_openvpn
else
    # user specified config file as argument #1
    CONFIG=$1
fi

# if invoked from cron job, always use config file from last run
# (by checking if interactive)
if [ ! -z "$PS1" ]; then
    if [ -f cat /var/local/openvpn-config ]; then
        CONFIG=$(cat /var/local/openvpn-config)
    fi
fi

# check if config file exists
if [ ! -f "$OPENVPN_CONFIG_DIR/${CONFIG}.ovpn" ]; then
    echo "No such file \"$OPENVPN_CONFIG_DIR/${CONFIG}.ovpn\"" >&2
    exit 1
fi

# save the file for next time (not implemented)
#echo $CONFIG > /var/local/openvpn-config

# check if openvpn is already running
if pgrep -x "openvpn" &> /dev/null ; then
    # openvpn is already running
    if ! is_cron ; then
        # not run from cron / interactive terminal, show error
        echo "openvpn is already running"  >&2
        exit 1
    fi
else
    # openvpn is not running, tail log if being run interactively so user can see progress
    restart_openvpn
    if ! is_cron ; then
        echo "Show output of $OPENVPN_LOG - Ctrl+C to exit..." >&2
        tail -f "$OPENVPN_LOG"
    fi
fi

exit 0


