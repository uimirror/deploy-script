#!/usr/bin/env bash
#set -xv

#***********************************************
#  Name: utilites.sh
#  Date: 26 March 2015
#  Usage: ./utilites.sh
#  It helps to get the current process id, uptime, statics
#  Restart the instance and stopping instances 
#**********************************************

#To Show the message
# cp -rv ./autodeploy.sh /home/kumarprd
usage(){

    echo "Usage : $0 -p <project_type> -j <java_version> -r <repo> -b <branch>
    E.g. : ./autodeploy.sh -p java -j 1.8 -r uimirror/rtp.git -b devlop
    project_type: Specifies which type of Project it is, i.e [java, other], default is java
    java_version: If Project type is Java, which java version to use, default is 1.8
    repo : path too git repo (e.g. uimirror/rtp.git)
    branch : devlop OR master (default is devlop if not mentioned)"
}
