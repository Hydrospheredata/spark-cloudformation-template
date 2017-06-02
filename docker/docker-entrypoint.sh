#!/bin/sh

set -e
cd ${MIST_HOME}

if [ "$1" = 'master' ]; then
  IP=$(cat /etc/hostname)
  ./bin/mist start master --config $MIST_CONFIG --java-args "-Dmist.akka.remote.netty.tcp.hostname=$IP -Dmist.akka.remote.netty.tcp.port=2551"
elif [ "$1" = 'worker' ]; then
  $SPARK_HOME/sbin/start-master.sh -h 0.0.0.0
  IP=$(cat /etc/hostname)
  ./bin/mist start worker --runner local --namespace $NAMESPACE --java-args "-Dmist.akka.remote.netty.tcp.hostname=$IP -Dmist.akka.remote.netty.tcp.port=2551" --config $MIST_CONFIG $RUN_OPTIONS
elif [ "$1" = 'single-worker' ]; then
  IP=$(cat /etc/hostname)
  ./bin/mist start worker --runner local --namespace $NAMESPACE --java-args "-Dmist.akka.remote.netty.tcp.hostname=$IP -Dmist.akka.remote.netty.tcp.port=2551" --config $MIST_CONFIG $RUN_OPTIONS
elif [ "$1" = 'spark-slave' ]; then
  $SPARK_HOME/sbin/start-slave.sh $2
  PID=`cat /tmp/spark-*.pid`
  echo "Started PID=$PID"
  while [ -e /proc/$PID ]
  do
    sleep 10
  done
  echo "Finished"
  ps aux
else
  exec "$@"
fi
