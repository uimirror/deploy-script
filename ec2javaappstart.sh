#!/usr/bin/env bash

#***********************************************
#  Name: ec2javaappstart.sh
#  Date: 9 Nov 2014
#  Usage: ./start.sh -port=8080 -nioport=8443 -env=prod
#
#**********************************************

APP_HOME=test
APP_SCRIPT_PATH=test

#To Show the message
usage(){

  echo "Usage : $0 -p <port_to_start> -n <nioport> -e <env>
        port_to_start : Tomcat to start on this port, default 8080
        nioport : ssl port
        env :  prod OR dev, default prod"

}
note_main_user(){
    MAIN_USER=$(whoami);
}
lets_re_login(){
    sudo -u $MAIN_USER ls>/dev/null;
    echo "Now Re Login as $(whoami)";
}
function is_port_free {
    #Return 1 if port free else 2
    netstat -ntpl | grep [0-9]:${1:-$1} -q ;

    if [ $? -eq 1 ]
    then
        return 1;
    else
        return 2;
    fi
}
#Confirmation if user wants me to sleep again
will_i_sleep(){
    read -rp "Do you want me to take rest again? (Y/N)" take_more_rest;
    shopt -s nocasematch;
    case "$take_more_rest" in
        y) echo "Taking Rest..."; lets_sleep;;
        *) echo "Enough Rest lets do some work";;
    esac
}
#Sleep methods
lets_sleep(){
    echo "Let me sleep for some time, till your application started up";
    read -rp "How long will be good for me you think?" SLEEP_TIMER;
    num_re='^[0-9]+$';
    if ! [[ $SLEEP_TIMER =~ $num_re ]] ; then
        echo "Wrong Input, I am taking rest for 1 mins then";SLEEP_TIMER='1m';
    else
        SLEEP_TIMER=$SLEEP_TIMER'm';
        echo "Thanks for allowing me to take rest for $SLEEP_TIMER" ;
    fi
    sleep $SLEEP_TIMER;
    echo "I am Back...";
    if ps -p $running_pid > /dev/null
    then
        echo "$running_pid is running"
        #Just to make sure the running PID is still actieve before asking whethere really app started
        will_i_sleep;
    else
        echo "Seems $running_pid is stopped, please check your app logs";
        echo "Bye!";
        exit 1;
    fi
}
#logging of the process ID
log_process_id(){
    lets_sleep;
    sudo sed -i.back "/^[0-9]\+\t$running_pid\t.*/d" $PID_FILE
    sudo sed -i.back "/^$tomcat_port\t[0-9]\+\t.*/d" $PID_FILE
    sudo rm -rf $PID_FILE.back;
    sudo echo -e "$tomcat_port\t$running_pid\t$nio_port\t$use_env\t$APP_HOME\t\t\t$APP_SCRIPT_PATH" >> $PID_FILE;
    echo "PID : $running_pid has been logged";
}
format_port(){
    if [[ $port == "" ]]; then
        echo "no port Specified, using default 8080";
        port=8080
    fi
    if [[ $( is_port_free $port) -eq 2 ]]; then
        echo "$port is used"
        exit 2;
    else
        tomcat_port=$port
    fi
}
format_nio_port(){
    #  echo $nioport
    if [[ $nioport == "" ]]; then
        echo "no nioport, using Default SSL Port 8443"
        nio_port=8443;
    else
        nio_port=$nioport;
    fi
}
format_env(){
    if [[ $env == "" ]]; then
        echo "no env mentioned, using prod"
        use_env=prod;
    else
        use_env=$env;
    fi
}

#formats the User Input
format_user_input(){
    format_port;
    format_nio_port;
    format_env;
}
#Invoke app process
invoke_app(){
    process_start_logs=$(sudo -u uim_tomcat ./start.sh -p $tomcat_port -n $nio_port -e $use_env);
    #JAVA_OPTS="-Denv=$use_env -Dport=$tomcat_port -Dnioport=$nio_port" ../bin/uim_api_explorer_conf > /dev/null 2>&1 &
    #get the exact process ID from the logs process_start_logs
    running_pid=$(echo $process_start_logs|awk '/^App Starting at ([0-9]+)/{ print $4 }');
    if [[ $running_pid == 0 ]]; then
        echo "Java Process has not be started, check app logs"
        exit 1;
    fi
    echo "App starting with process ID $running_pid";

}
PID_FILE=/uim/deploy/extra/uimirror.pid
if [[ $1 == "-h" || $1 == --help ]]; then
  usage
else
    while getopts ":p:n:e:" opt;
        do
            case $opt in
                p|--port) port=$OPTARG;;
                n) nioport=$OPTARG;;
                e) env=$OPTARG;;
                \?) echo "Invalid option";
                    exit 1;
                    ;;

                :) echo "Option -$OPTARG requires an argument." >&2
                    exit 1
                    ;;
            esac
        done
fi
note_main_user;
#Now format user's input
format_user_input;
#Now Invoke application
invoke_app;
#now back to the normal user
lets_re_login;
#lets log the process ID
log_process_id;
exit 0;
