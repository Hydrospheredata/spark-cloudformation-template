#!/bin/bash

while [ "$1" != "" ]; do
    PARAM=`echo $1 | awk -F= '{print $1}'`
    VALUE=`echo $1 | awk -F= '{print $2}'`
    case $PARAM in
        --namespace)
            ARG_NAMESPACE=$VALUE
            ;;
        *)
            echo "ERROR: unknown parameter \"$PARAM\""
            usage
            exit 1
            ;;
    esac
    shift
done

EC2_REGION=$(curl -s http://169.254.169.254/latest/dynamic/instance-identity/document | jq -r .region)
aws configure set default.region $EC2_REGION
ORIGINAL_TEMPLATE=$(aws cloudformation get-template --stack-name $STACK_NAME | jq .TemplateBody)

temp=$(echo $ORIGINAL_TEMPLATE | jq "del(.Resources .LCSparkSlave$ARG_NAMESPACE)")
temp=$(echo $temp | jq "del(.Resources .ASGroupSparkSlave$ARG_NAMESPACE)")
temp=$(echo $temp | jq "del(.Resources.LCWorker$ARG_NAMESPACE)")
temp=$(echo $temp | jq "del(.Resources .ASGroupWorker$ARG_NAMESPACE)")
temp=$(echo $temp | jq "del(.Resources .SparkSlaveService$ARG_NAMESPACE)")
temp=$(echo $temp | jq "del(.Resources .MistWorkerService$ARG_NAMESPACE)")
temp=$(echo $temp | jq "del(.Resources .SparkSlavesTaskDefinition$ARG_NAMESPACE)")
temp=$(echo $temp | jq "del(.Resources .WorkerTaskDefinition$ARG_NAMESPACE)")

tfile=$(mktemp /tmp/foo.XXXXXXXXX)
echo  $temp > $tfile
aws cloudformation update-stack --stack-name $STACK_NAME --template-body file://$tfile --parameters ParameterKey=KeyName,UsePreviousValue=true ParameterKey=EcsClusterName,UsePreviousValue=true ParameterKey=EcsInstanceType,UsePreviousValue=true ParameterKey=RootUrlDownload,UsePreviousValue=true ParameterKey=MistVersion,UsePreviousValue=true ParameterKey=SparkVersion,UsePreviousValue=true ParameterKey=SparkSlavesCount,UsePreviousValue=true ParameterKey=SparkInstanceType,UsePreviousValue=true ParameterKey=EFSNameTag,UsePreviousValue=true --capabilities CAPABILITY_IAM