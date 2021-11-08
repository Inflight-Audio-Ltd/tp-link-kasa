#!/bin/sh

hostname='everair123'

timestamp()
{
	ts=$(date +"[%Y-%m-%d %H:%M:%S]")
	echo ${ts} $1
}

reset_wifi()
{
	ifconfig en11 down
	sleep 5
	ifconfig en11 up
	sleep 15
}

check_hostname()
{
	expectedHostname=$1
	res=$(ssh \
		-i /Users/lucasy/.ssh/id_rsa \
		-o ConnectTimeout=5 \
		-o StrictHostKeyChecking=no \
		-o UserKnownHostsFile=/dev/null \
		-o LogLevel=error \
		ifdadmin@192.168.8.139 hostname 2>&1)
	if [ "${res}" == "${expectedHostname}" ]; then
		echo "check_hostname: OK"
		return 0
	fi
	echo "check_hostname: ERROR"
	echo "res: ${res}"
	return 1
}

if [ $UID != 0 ];then
	echo "Must be run as root" >&2
	exit 1
fi

if ! check_hostname $hostname; then
	echo "Hostname not correct. Test aborted." >&2
	exit 1
fi


echo -e "How many times you like to repeat the task? Note 1< times <1000 \n"
read option

if [ "$option" -ge 1 ] && [ "$option" -le 1000 ]
then 

	timestamp "### START ###"
	for i in $(seq $option); do
		timestamp "## pass $i start ##"
		timestamp "Switching box off..."

		./smartplug_off.sh
		sleep 120

		timestamp "Switching box on..."
		./smartplug_on.sh

		timestamp "Waiting for box to boot..."
		sleep 120

		timestamp "Checking hostname..."
		if ! check_hostname $expectedHostname; then
			timestamp "hostname: ERROR"
			exit 1
		fi
		timestamp "## pass $i end ##"	
	done

else
    echo -e "Input option must be a numbers between 1 and 1000 \n" 
	exit 0

fi