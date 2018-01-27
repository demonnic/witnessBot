#!/usr/bin/env bash
if [ -f "./pid.txt" ]
then
  pid=`cat ./pid.txt`
fi
if [ -z "$pid" ]
then
  nohup ruby witness.rb 2>&1 >>witness.log &
  echo $! > pid.txt
  exit
fi
ps -ef | grep -v grep | grep $pid
if [ $? -eq 1 ]
then
  nohup ruby witness.rb 2>&1 >>witness.log &
  echo $! > pid.txt
  exit
fi
echo "witness is already running"
