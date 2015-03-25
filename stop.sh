#!/usr/bin/env bash

#***********************************************
#  Name: stop.sh
#  Date: 9 Nov 2014
#  Usage: ./stop.sh -p=<port_to_locate_pid> -i=<pid_if_known>
#         port can be specifed array of ports comma seperated like 8080,8181
#         pid can be specified array of pids comma seperated
# It requires either both or any one of the identifier to locate the process IDS, so that it can
# kill all the process attached to it.
#
#**********************************************


#To Show the message
usage(){
    echo "Usage : $0 -p <port_to_find_pid> -i <process_id>
    port_to_find_pid : Port id to kill
    process_id : process id to kill
    When user provided process id, then irrespective of its found or not in the PID file but it will kill the process"
}

#Resloves the pid given in the pid parameter to the process id's
resolve_PID_from_port(){
    OIFS=$IFS;
    IFS=",";

    for x in $PORT
        do
            exp=$x' : ';
            temp_found_pid=$((grep -Po "(?<=^$exp).*" $PID_FILE)|xargs);
            if [[ "$temp_found_pid" ]]; then
                if [[ "$PID_TO_KILL" ]]; then
                    PID_TO_KILL=$PID_TO_KILL' '$temp_found_pid;
                else
                    PID_TO_KILL=$temp_found_pid;
                fi
            fi
        done
    echo "Found Matching process ID(s): $PID_TO_KILL"
    IFS=$OIFS;
}
#Split the provided
preety_format_pid(){
    OIFS=$IFS;
    IFS=",";

    for x in $PID
        do
            temp_found_pid=$(echo $x|xargs)
            if [[ "$temp_found_pid" ]]; then
                if [[ "$PID_TO_KILL" ]]; then
                    PID_TO_KILL=$PID_TO_KILL' '$temp_found_pid;
                else
                    PID_TO_KILL=$temp_found_pid;
                fi
            fi
        done
    echo "Formated process ID(s): $PID_TO_KILL"
    IFS=$OIFS;
}

#this will remove the PID entries from logging file
clear_pid_entries(){
    OIFS=$IFS;
    IFS=" ";
    for x in $PID_TO_KILL
        do
            sudo sed -i.back "/^[0-9]\+ :  $x/d" $PID_FILE
        done
    sudo rm -rf $PID_FILE.back
    echo "Process ID has been cleared from the log"
    IFS=$OIFS;
}

#Will kill all the resolved PID
kill_processes(){
    if [[ "$PID_TO_KILL" ]]; then
        PID_TO_KILL=$(echo $PID_TO_KILL|xargs)
        sudo kill -9 $PID_TO_KILL
    else
        echo "Nothing to kill"
    fi
}

PID_FILE=/tmp/uimirror.pid;
PID_TO_KILL='';
if [[ $1 == "-h" || $1 == --help ]]
    then
        usage
    else
    while getopts ":p:i:" opt;
        do
        case $opt in
            p) PORT=$OPTARG;;
            i) PID=$OPTARG;;
            \?) echo "Invalid options, see the usage";
            usage;
            sayBye;
            exit 1;
            ;;
        esac
        done
fi

echo "Hello, I got request to kill process";

#Now process for the process id finding if it was a port number
if [[ "$PORT" ]]; then
    resolve_PID_from_port;
fi

if [[ "$PID" ]]; then
    preety_format_pid;
fi
kill_processes;
echo "I have stoped all identified process. I am done!!! Bye!"