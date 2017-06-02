#!/bin/sh

while [ "$1" != "" ]; do
    PARAM=`echo $1 | awk -F= '{print $1}'`
    VALUE=`echo $1 | awk -F= '{print $2}'`
    case $PARAM in
        --namespace)
            ARG_NAMESPACE=$VALUE
            ;;
        --config)
            ARG_CONFIG=$VALUE
            ;;
        --run-options)
            ARG_RUN_OPTIONS=$VALUE
            ;;
        --jar)
            ARG_JAR=$VALUE
            ;;
        *)
            echo "ERROR: unknown parameter \"$PARAM\""
            usage
            exit 1
            ;;
    esac
    shift
done

LC_TEMPLATE_FILE=$MIST_HOME/bin/template/mist-worker-launchconfiguration.json
AS_TEMPLATE_FILE=$MIST_HOME/bin/template/mist-single-worker.json
CREATE_SPARK_TEMPLATE_FILE=$MIST_HOME/bin/template/mist-worker-services.json

ORIG_LAUNCH_CONFIG_NAME=MistMasterLaunchConfiguration
ORIG_INSTANCE_SECURITY_GROUP=InstanceSecurityGroup
ORIG_AUTO_SCALING=MistMasterInstanceAsg
MASTER_ROLE_NAME=role_master

EC2_REGION=$(curl -s http://169.254.169.254/latest/dynamic/instance-identity/document | jq -r .region)
aws configure set default.region $EC2_REGION
ORIGINAL_TEMPLATE=$(aws cloudformation get-template --stack-name $STACK_NAME | jq .TemplateBody)

ADD="{}"
if [ "$START_SPARK_CLUSTER" == "yes" ]; then
    ##add spark slaves
    launchConfiguration=$(cat $LC_TEMPLATE_FILE)
    launchConfiguration=$(echo $launchConfiguration | sed -e "s/__RESOURCE_NAME__/$launchCName/g")
    launchConfiguration=$(echo $launchConfiguration | sed -e "s/__TYPE__/SparkSlave/g")
    launchConfiguration=$(echo $launchConfiguration | sed -e "s/__NAMESPACE__/$ARG_NAMESPACE/g")
    launchConfiguration=$(echo $launchConfiguration | sed -e "s/__INSTANCE_ROLE__/role_spark_slave/g")
    launchConfiguration=$(echo $launchConfiguration | sed -e "s/__INSTANCE_COUNT__/$SPARK_SLAVE_SCOUNT/g")
    launchConfiguration=$(echo $launchConfiguration | sed -e "s/__SPOT_PRICE__/$SPARK_SPOT_PRICE/g")

    ADD=$(echo '{}' | jq "$ADD + $launchConfiguration")

    AS_TEMPLATE_FILE=$(echo $CREATE_SPARK_TEMPLATE_FILE)
fi

launchConfiguration=$(cat $LC_TEMPLATE_FILE)
launchConfiguration=$(echo $launchConfiguration | sed -e "s/__RESOURCE_NAME__/$launchCName/g")
launchConfiguration=$(echo $launchConfiguration | sed -e "s/__TYPE__/Worker/g")
launchConfiguration=$(echo $launchConfiguration | sed -e "s/__NAMESPACE__/$ARG_NAMESPACE/g")
launchConfiguration=$(echo $launchConfiguration | sed -e "s/__INSTANCE_ROLE__/role_worker/g")
launchConfiguration=$(echo $launchConfiguration | sed -e "s/__INSTANCE_COUNT__/1/g")
launchConfiguration=$(echo $launchConfiguration | sed -e "s/__SPOT_PRICE__/$SPARK_SPOT_PRICE/g")


ADD=$(echo '{}' | jq "$ADD + $launchConfiguration")

launchConfiguration=$(cat $AS_TEMPLATE_FILE)
launchConfiguration=$(echo $launchConfiguration | sed -e "s|__MIST_CONFIG__|$ARG_CONFIG|g")
launchConfiguration=$(echo $launchConfiguration | sed -e "s/__NAMESPACE__/$ARG_NAMESPACE/g")
launchConfiguration=$(echo $launchConfiguration | sed -e "s/__INSTANCE_COUNT__/$SPARK_SLAVE_SCOUNT/g")
launchConfiguration=$(echo $launchConfiguration | sed -e "s/__RUN_OPTIONS__/$ARG_RUN_OPTIONS/g")

ADD=$(echo '{}' | jq "$ADD + $launchConfiguration")
temp=$(echo $ORIGINAL_TEMPLATE | jq ".Resources = (.Resources + $ADD)")

tfile=$(mktemp /tmp/foo.XXXXXXXXX)
echo  $temp > $tfile

aws cloudformation update-stack --stack-name $STACK_NAME --template-body file://$tfile --parameters \
    ParameterKey=KeyName,UsePreviousValue=true \
    ParameterKey=EcsClusterName,UsePreviousValue=true \
    ParameterKey=EcsInstanceType,UsePreviousValue=true \
    ParameterKey=RootUrlDownload,UsePreviousValue=true \
    ParameterKey=MistVersion,UsePreviousValue=true \
    ParameterKey=SparkVersion,UsePreviousValue=true \
    ParameterKey=SparkSlavesCount,UsePreviousValue=true \
    ParameterKey=SparkSpotPrice,UsePreviousValue=true \
    ParameterKey=SparkInstanceType,UsePreviousValue=true \
    ParameterKey=EFSNameTag,UsePreviousValue=true \
    ParameterKey=RouteConfigurationFile,UsePreviousValue=true \
    ParameterKey=ConfigurationFile,UsePreviousValue=true \
    ParameterKey=MistImageName,UsePreviousValue=true \
    ParameterKey=StartSparkCluster,UsePreviousValue=true \
    ParameterKey=SSHLocation,UsePreviousValue=true \
    ParameterKey=CIDRVPC,UsePreviousValue=true \
    ParameterKey=CIDRSubnet1,UsePreviousValue=true \
    ParameterKey=CIDRSubnet2,UsePreviousValue=true \
    --capabilities CAPABILITY_IAM