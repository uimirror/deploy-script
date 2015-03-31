#!/usr/bin/env bash
#set -xv

#***********************************************
#  Name: utilityworker.sh
#  Date: 28 March 2015
#  Usage: ./utilityworker.sh
#  It helps to get the current process id, uptime, statics
#  Restart the instance and stopping instances
#**********************************************

#To Show the message
usage(){
    echo "Usage : $0 [-p pid | --pid pid] [--port port] [--pidfile PID_FILE_LOCATION] [-h | --help] -- Program to show health statics of a process ID.
    Where :
        -p|--pid PROCESS_ID for which process ID information needs to be extracted
        --port PORT for which port information needs to be extracted
        --pidfile PID_MAPPING_FILE_LOCATION which has the port and pid mapping
        -h|--help to see usage message
    Error Code :
        1- in case of error
        0- In case of success
    "
}
note_main_user(){
    MAIN_USER=$(whoami);
}

lets_re_login(){
    sudo -u $MAIN_USER ls>/dev/null;
    echo "Now Re Login as $(whoami)";
}

PID=;
PORT=;
PID_FILE_LOC='/tmp/uimirror.pid';
APP_PATH='';
APP_SCRIPT_PATH='';

#Clears the previous output and process
function press_enter
{
    echo ""
    echo -n "Press Enter to continue"
    read
    clear
}
check_pid_file_exists(){
    if [ ! -f "$PID_FILE_LOC" ]; then echo "PID Mapping File Not Found!!! Abroating"; exit 1; fi
}
#reads the file mapping location from user
get_pid_file_mapping(){
    read -rp "Ok, Enter the Port-PID Mapping File Location: " PID_FILE_LOC;
    check_pid_file_exists;
}
#Confirm the PID file location
get_confirmed_pid_file_loc(){
    read -rp "I am going to look at $PID_FILE_LOC for PID-Port mapping, please confirm (Y/N)?" PID_FILE_LOC_CONF;
    shopt -s nocasematch;
    case "$PID_FILE_LOC_CONF" in
        y) check_pid_file_exists;;
        *) get_pid_file_mapping;;
    esac
}
#Resolve PID, Port, App Home and App Script Path
resolve_pid_port_map(){
    if [[ "$PORT" ]]; then
        APP_PATH=$(grep -P "^$PORT\t[0-9]+\t.*" $PID_FILE_LOC |awk '{print $5}');
        APP_SCRIPT_PATH=$(grep -P "^$PORT\t[0-9]+\t.*" $PID_FILE_LOC |awk '{print $6}');
        NIO_PORT=$(grep -P "^$PORT\t[0-9]+\t.*" $PID_FILE_LOC |awk '{print $3}');
        ENV=$(grep -P "^$PORT\t[0-9]+\t.*" $PID_FILE_LOC |awk '{print $4}');
        PID=$(grep -P "^$PORT\t[0-9]+\t.*" $PID_FILE_LOC |awk '{print $2}');
        PORT=$(grep -P "^$PORT\t[0-9]+\t.*" $PID_FILE_LOC |awk '{print $1}');
    else
        APP_PATH=$(grep -P "^[0-9]+\t$PID\t.*" $PID_FILE_LOC |awk '{print $3}');
        APP_SCRIPT_PATH=$(grep -P "^[0-9]+\t$PID\t.*" $PID_FILE_LOC |awk '{print $4}');
        NIO_PORT=$(grep -P "^[0-9]+\t$PID\t.*" $PID_FILE_LOC |awk '{print $3}');
        ENV=$(grep -P "^[0-9]+\t$PID\t.*" $PID_FILE_LOC |awk '{print $4}');
        PID=$(grep -P "^[0-9]+\t$PID\t.*" $PID_FILE_LOC |awk '{print $2}');
        PORT=$(grep -P "^[0-9]+\t$PID\t.*" $PID_FILE_LOC |awk '{print $1}');
    fi

    if [[ ! "$PORT" || ! "$PID" ]]; then
        echo "Not able to find any mapping between PID-Port and App home";
        exit 1;
    fi

}
#Starts the process
start_process(){
    sudo ./$APP_PATH$APP_SCRIPT_PATH'ec2javaappstart.sh' -p $PORT -n $NIO_PORT -e $ENV;
    lets_re_login;
    PID='';
    echo "Reloacting PID entery"
    resolve_pid_port_map;
}
#Restart the process and remap the port and PID
restart_process(){
    stop_process;
    echo "I am sleeping for 2 minutes";
    sleep 2m;
    echo "I Woke Up starting process";
    start_process;
}
#This will call the stop.sh to stop the process
stop_process(){
    echo "sudo $APP_PATH$APP_SCRIPT_PATH --pid $PID";
    sudo ./$APP_PATH$APP_SCRIPT_PATH'stop.sh' --pid $PID;
    lets_re_login;
    echo "Process Stopped"
}
#Stops the process and delete the Binary
stop_and_sclen_process(){
    stop_process;
    read -rp "Do you really want to delete the binaries, please confirm (Y/N)?" BINARY_REMOVE_CONF;
    shopt -s nocasematch;
    case "$BINARY_REMOVE_CONF" in
        y) sudo rm -rf $APP_PATH;echo "Project Deleted, Please Unmap from webserver for the port $PORT";sayBye;exit 0 ;;
    esac

}
#Prints ths process UP Time
print_up_time(){
    echo "Uptime in [[dd-]hh:]mm:ss";
    uptime=$(ps -p $PID -o etime=);
    echo "$uptime";
}
#Prints Disk Statics
print_disk_stack(){
    echo "Overall Disk Stat:";echo "$(sudo df -H -g)";
    read -rp "Do you want the disk space of a specific path(Y/N)?" DF_LOC_CONF;
    shopt -s nocasematch;
    case "$DF_LOC_CONF" in
    y) read -rp "Enter the path: " DF_LOC_PATH; echo "Disk Stat for $DF_LOC_PATH :"; echo "$(sudo df -H -g -h $DF_LOC_PATH)";;
esac
}
#Print Free Memory Statics
print_free_stat(){
    echo "Free Memory Statics: ";
    echo "$(top -l 1 | head -n 10 | grep PhysMem | sed 's/, /\n         /g')";
}
#Prints JVM Actieve Thread count
print_jvm_active_thread(){
    echo "Active Thread for the process $PID : $(ps huH p $PID | wc -l)";
}
#First clear the screen
press_enter;

#Main
while [ "$1" != "" ]; do
    case $1 in
        -p | --pid )
            shift
            PID=$1;
            if [[ "$PORT" ]]; then
                echo "Please Specify either Port or PID"
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
            ;;
    esac
    shift
done

note_main_user;

#Get a User Confirmation for PID file mapping location
get_confirmed_pid_file_loc;

#Resolve the PID and Port mapping
resolve_pid_port_map;

selection=
until [ "$selection" = "0" ]; do
    echo ""
    echo "PROGRAM MENU"
    echo "1 - Display Free Disk Space"
    echo "2 - Display Free Memory"
    echo "3 - Display Up Time $PORT"
    echo "4 - Restart Process $PID"
    echo "5 - Stop Process $PID"
    echo "6 - Start Process in port $PORT"
    echo "7 - Do a Clean Stop Process for $PID"
    echo "8 - Display Incomming/Outgoing Statics for Port $PORT"
    echo "9 - Display Number of actieve threads for PID $PID"
    echo ""
    echo "0 - Exit Program"
    echo ""
    echo -n "Enter Selection: "
    read selection
    echo ""
    case $selection in
        1 ) print_disk_stack ; press_enter ;;
        2 ) print_free_stat ; press_enter ;;
        3 ) print_up_time;;
        4 ) echo restart_process;;
        5 ) stop_process;;
        6 ) start_process;;
        7 ) stop_and_sclen_process;;
        8 ) echo "asgga";;
        9 ) print_jvm_active_thread;;
        0 ) exit ;;
        * ) echo "Please Enter 1, 2, 3, 4, 5, 6, 7, 8, 9 or 0"; press_enter
    esac
done


