#!/bin/bash

set -eu
source /etc/ecs/ecs.config

EC2_AVAIL_ZONE=`curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone`
EC2_REGION=$(curl -s http://169.254.169.254/latest/dynamic/instance-identity/document | jq -r .region)

EFS_FILE_SYSTEM_ID=$(/usr/local/bin/aws efs describe-file-systems --region $EC2_REGION | jq '.FileSystems[]' | jq "select(.Name==\"${EFS_NAME}\")" | jq -r '.FileSystemId')

#Check to see if the variable is set. If not, then exit.
if [-z "$EFS_FILE_SYSTEM_ID"]; then
 echo "ERROR: variable not set"
 exit
fi

DIR_SRC=$EC2_AVAIL_ZONE.$EFS_FILE_SYSTEM_ID.efs.$EC2_REGION.amazonaws.com
DIR_TGT=/mnt/efs

mkdir -p $DIR_TGT
#Mount EFS file system
mount -t nfs4 $DIR_SRC:/ $DIR_TGT
#Backup fstab
cp -p /etc/fstab /etc/fstab.back-$(date +%F)
#Append line to fstab
echo -e "$DIR_SRC:/ \t\t $DIR_TGT \t\t nfs \t\t defaults \t\t 0 \t\t 0" | tee -a /etc/fstab

service docker stop
service docker start
#Create folders if this needs
if [ ! -d "$DIR_TGT/mist-configs" ]; then
    mkdir $DIR_TGT/mist-configs
    cd $DIR_TGT/mist-configs

    #copy files
    curl -O $ROOT_URL_DOWNLOAD/mist-conf/default.conf
    curl -O $ROOT_URL_DOWNLOAD/mist-conf/router.conf
fi