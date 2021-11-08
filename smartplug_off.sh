#!/bin/sh

cloudUserName="miguelanxo@telefonica.net"
cloudPassword="kasa2020"
terminalUUID="931eedda-5161-11ea-8d77-2e728ce88125"
appServerUrl="https://eu-wap.tplinkcloud.com"
deviceId="80065975CD5C766EDD7C72B88DD7D8DB1B85DD6B"

kasa_login() {
	res=$(curl -s \
        -X POST \
		-H "Content-Type: application/json" \
		-d "{'method':'login','params':{'appType':'Kasa_Android','cloudUserName':'${cloudUserName}','cloudPassword':'${cloudPassword}','terminalUUID':'${terminalUUID}'}}" \
		"https://wap.tplinkcloud.com")
	errorCode=$(echo $res|jq -r .error_code)
	if [ "${errorCode}" != "0" ]; then
		echo "kasa_login: error $errorCode"
		exit 1
	fi
	token=$(echo $res|jq -r .result.token)	
	echo $token
}

kasa_get_device_list()
{
	token=$1

	res=$(curl -s \
		-X POST \
		-H "Content-Type: application/json" \
		-d "{'method':'getDeviceList'}" \
		"https://wap.tplinkcloud.com?token=${token}")
	errorCode=$(echo $res|jq .error_code)
	if [ ${errorCode} != 0 ]; then
		echo "kasa_get_device_list: error $errorCode"
		exit 1
	fi
	echo $res|jq .
	exit 0
}

kasa_set_device_state()
{
	token=$1
	appServerUrl=$2
	deviceId=$3
	newDeviceState=$4

	res=$(curl -s \
		-X POST \
		-H "Content-Type: application/json" \
		-d "{\"method\":\"passthrough\",\"params\":{\"deviceId\":\"${deviceId}\",\"requestData\":'{\"system\":{\"set_relay_state\":{\"state\":${newDeviceState}}}}'}}" \
		"${appServerUrl}?token=$token")
	errorCode=$(echo $res|jq .error_code)
	if [ "${errorCode}" != "0" ]; then
		echo "kasa_set_device_state: error $errorCode"
		return 1
	fi
	return 0
}

kasa_switch_device_on()
{
	token=$1
	appServerUrl=$2
	deviceId=$3

	kasa_set_device_state $1 $2 $3 1
}

kasa_switch_device_off()
{
	token=$1
	appServerUrl=$2
	deviceId=$3

	kasa_set_device_state $1 $2 $3 0
}

maxAttempts=10
attemptDelay=1
attempts=0
while (true); do
	token=$(kasa_login)
	if (kasa_switch_device_off $token $appServerUrl $deviceId);then
		exit 0
	fi
	echo "Error switching device off." >&2
	attempts=$(( ${attempts} + 1 ))
	if [ $attempts -gt ${maxAttempts} ]; then
		echo "Max attempts exceeded. Giving up." >&2
		exit 1
	fi
	echo "Trying again in $attemptDelay seconds..."
	sleep $attemptDelay
	attemptDelay=$(( ${attemptDelay} * 2 ))
done
