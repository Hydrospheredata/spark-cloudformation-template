#!/bin/bash

set -eu
source /etc/ecs/ecs.config

export AWS_DEFAULT_REGION=$(curl -s http://169.254.169.254/latest/dynamic/instance-identity/document | jq -r .region)
instancesIps=($(/usr/local/bin/aws ec2 describe-instances --filters Name=tag:aws:cloudformation:stack-name,Values=$STACK_NAME | jq -r '.Reservations | .[] | .Instances | .[] | .PrivateIpAddress'))
peerIps=""
localIp=`ifconfig eth0 2>/dev/null|awk '/inet addr:/ {print $2}'|sed 's/addr://'`
for instanceIp in "${instancesIps[@]}"
do
    if [ "$localIp" != "$instanceIp" ] && [ "$instanceIp" != "null" ]; then
        peerIps="$peerIps $instanceIp"
    fi
done
echo $peerIps