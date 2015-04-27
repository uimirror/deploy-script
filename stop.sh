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
    echo "Usage : $0 [--port <port_ids>] [--pid <pids>] [-h | --help] to stop any process or port               mapped based apps.

    Where:
        --port port numbers to be get cleaned i.e 8080,8181,8282
        --pid  pid numbers to be get cleaned/killed i.e 1234,5678
        -h|--help to understand the usage and help information

    Error Codes :
        1- In case of error
        0- In case of sucess
        "
}

#Resloves the pid given in the pid parameter to the process id's
resolve_PID_from_port(){
    OIFS=$IFS;
    IFS=",";
    for x in $PORT
        do
            temp_found_pid=$((grep -P "$x\t[0-9]+\t.*" $PID_FILE|awk '{print $2}')|xargs);
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
    APP_PATH='';
    for x in $PID_TO_KILL
        do
            if [[ "$APP_PATH" ]]; then
                APP_PATH=$APP_PATH' '$(grep -P "^[0-9]+\t$x\t.*" $PID_FILE |awk '{print $3}');
            else
                APP_PATH=$(grep -P "^[0-9]+\t$x\t.*" $PID_FILE |awk '{print $3}');
            fi
            sudo sed -i.back "/^[0-9]\+\t$x\t.*/d" $PID_FILE
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

PID_FILE=/uim/deploy/extra/uimirror.pid;
PID_TO_KILL='';
#Main
while [ "$1" != "" ]; do
    case $1 in
        --port )
            shift
            PORT=$1;
            if [[ "$PID" ]]; then
                echo "Please Specify either Port or PID comma seperated."
                usage;
                exit 1;
            fi
            ;;
        --pid )
            shift
            PID=$1;
            if [[ "$PORT" ]]; then
                echo "Please Specify either Port or PID comma seperated."
                usage;
                exit 1;
            fi
            ;;
        -h | --help )
            usage
            exit
            ;;
        * )
            usage
            exit 1
    esac
    shift
done

echo "Hello, I got request to kill process";

#Now process for the process id finding if it was a port number
if [[ "$PORT" ]]; then
    resolve_PID_from_port;
fi

if [[ "$PID" ]]; then
    preety_format_pid;
fi

kill_processes;

#Now clean the PID Entery
clear_pid_entries;

echo "I have stoped all identified process. I am done!!! Bye!"