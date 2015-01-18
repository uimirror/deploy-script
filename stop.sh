#!/usr/bin/env bash

pid_file="/var/run/uimirror.pid"


while read line
do
 pid=$(awk -F: '{print $2}' $line)
 kill  $pid
 sed -i "/$pid/d" $pid_file
done < $pid_file 
 


