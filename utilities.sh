#!/usr/bin/env bash
#set -xv

#***********************************************
#  Name: utilites.sh
#  Date: 26 March 2015
#  Usage: ./utilites.sh -h
#  It helps to get the current process id, uptime, statics
#  Restart the instance and stopping instances 
#**********************************************

#To Show the message
usage(){
    echo "Usage : $0 [-l | --local] [-r ip | --remote ip] [-u user | --user user] [-k key_path | --key key_path] 
            [-p pid | --pid pid] [--port port] [--pidfile PID_FILE_LOCATION] [-h | --help] -- Program to show health statics of a process ID.
    Where :
        -l|--local use Local System to get the statics of process
        -r|--remote remote_ip of the remote machiene to get the statics of process
        -u|--user user_id to connect to the remote System or Admin account id of the local system
        -k|--key SSH_KEY_PATH to identify to the remote System
        -p|--pid PROCESS_ID for which process ID information needs to be extracted
        --port PORT for which port information needs to be extracted
        --pidfile PID_MAPPING_FILE_LOCATION which has the port and pid mapping
        -h|--help to see usage message
    Error Code :
        1- in case of error
        0- In case of success
        "
}
sayBye(){
    echo "Bye";
}

process_local_system(){
    if [ ! -f "$WORKER_SCRIPT" ]; then echo "PID Mapping File Not Found!!! Abroating"; exit 1; fi;
    if [[ "$PORT" ]]; then
        sudo ./$WORKER_SCRIPT --port $PORT --pidfile $PID_FILE_LOC
    else
        sudo ./$WORKER_SCRIPT --pid $PID --pidfile $PID_FILE_LOC
    fi

}

process_remote_system(){
    if [[ "$PORT" ]]; then
        ssh -i $SSH_KEY_LOC $USER@$REMOTE_IP -t "bash -l -c 'if [ ! -f $WORKER_SCRIPT ]; then echo PID Mapping File Not Found!!! Abroating; exit 1; fi; sudo ./$WORKER_SCRIPT --port $PORT --pidfile $PID_FILE_LOC;'"
    else
        ssh -i $SSH_KEY_LOC $USER@$REMOTE_IP -t "bash -l -c 'if [ ! -f $WORKER_SCRIPT ]; then echo PID Mapping File Not Found!!! Abroating; exit 1; fi; sudo ./$WORKER_SCRIPT --pid $PID --pidfile $PID_FILE_LOC;'"
    fi

}

#Validate the user inputs and valid combinations
validate_input(){
    #First validate the system types
    if [[ $IS_LOCAL == 0 ]] && [[ $IS_REMOTE == 0 ]]; then
        echo "Please Specify from which Machine to show statics";
        usage;
        exit 1;
    fi
    #Second validate the PORT and PID
    if [[ ! "$PORT" ]] && [[ ! "$PID" ]]; then
        echo "Please Specify either PID/Port";
        usage;
        exit 1;
    fi

}
IS_LOCAL=0;
IS_REMOTE=0;
REMOTE_IP=;
USER=;
PID=;
PORT=;
SSH_KEY_LOC=;
PID_FILE_LOC='/tmp/uimirror.pid';
num_re='^[0-9]+$';
WORKER_SCRIPT='utilityworker.sh';
#Main
while [ "$1" != "" ]; do
    case $1 in
        -l | --local )
            if [[ $IS_REMOTE == 1 ]]; then
                echo "Please Specify One System, either local or remote to get statics";
                usage;
                exit 1;
            fi
            IS_LOCAL=1;
            ;;
        -r | --remote )
            if [[ $IS_LOCAL == 1 ]]; then
                echo "Please Specify One System, either local or remote to get statics";
                usage;
                exit 1;
            fi
            IS_REMOTE=1;
            shift
            REMOTE_IP=$1;
            ;;
        -u | --user )
            shift
            USER=$1;
            ;;
        -k | --key )
            shift
            SSH_KEY_LOC=$1;
            ;;
        -p | --pid )
            shift
            PID=$1;
            if [[ "$PORT" ]]; then
                echo "Please Specify either Port or PID"
                usage;
                exit 1;
            fi
            if ! [[ $PID =~ $num_re ]] ; then
                echo "Invalid PID number, PID can be only numeric";
                usage;
                exit 1;
            fi
            ;;
        --port )
            shift
            PORT=$1;
            if [[ "$PID" ]]; then
                echo "Please Specify either Port or PID";
                usage;
                exit 1;
            fi
            if ! [[ $PORT =~ $num_re ]] ; then
                echo "Invalid port number, port can be only numeric";
                usage;
                exit 1;
            fi
            ;;
        --pidfile )
            shift
            PID_FILE_LOC=$1;
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

#Now validate the input
validate_input;

#Process the main logic
if [[ $IS_LOCAL == 1 ]]; then
    echo "Processing for Local System...";
    process_local_system
else
    echo "Processing for Remote System...";
    process_remote_system;
fi
