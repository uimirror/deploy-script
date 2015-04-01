#!/usr/bin/env bash
#set -xv
#**********************************
#   Name: ec2_deploy.sh
#   Date: 06th March 2015
#   Usage sudo ./ec2_deploy.sh
#   Return Codes: 1- Pre Requesties failed
#                 2- Java Server Instance start up failure
#                 0- Sucessful execution
#**********************************

####script will be substute with dynamic value and copied to EC2#######
PROJECT_TYPE=java
BINARY_FILE_NAME=test
JAVA_VERSION=1.8
PROJECT_NAME=test
SERVER_IP=test
SCRIPT_FOLDER=scripts

UTILITY_SCRIPT_LOC='/uim/deploy/scripts'
UTILITY_SCRIPT_NAME='utilities.sh'
UTILITY_SCRIPT_WORKER_NAME='utilityworker.sh'

#Prints Bye Message before closing the Script
sayBye(){
    echo "Bye!!!";
}

note_main_user(){
    MAIN_USER=$(whoami);
}
lets_re_login(){
    sudo -u $MAIN_USER ls>/dev/null;
    echo "Now Re Login as $(whoami)";
}

#Java Version Checker
java_version_check(){
    echo "Checking Java Version $1 ...";

    if type -p java; then
        echo "found java executable in PATH"
        _java=java
    elif [[ -n "$JAVA_HOME" ]] && [[ -x "$JAVA_HOME/bin/java" ]];  then
        echo "found java executable in JAVA_HOME"
        _java="$JAVA_HOME/bin/java"
    else
        echo "No java Found Probably Your have not set JAVA_HOME properly.";
        sayBye;
        exit 1;
    fi

    if [[ "$_java" ]]; then
        version=$("$_java" -version 2>&1 | awk -F '"' '/version/ {print $2}')
        echo "Found Java version $version"
        if [[ "$version" > "$1" ]]; then
            echo "Perfect Found Required Java Version.";
        else
            echo "Java version is less than $1 , Please Upgrade Java and try again."
            sayBye;
            exit 1;
        fi
    fi
}

printServerAndIp(){
    echo "Add Below Entry in the web server for the project $PROJECT_NAME";
    for used_port in "${JAVA_INSTANCE_PORTS[@]}"
        do
            echo "$SERVER_IP:$used_port or 127.0.0.1:$used_port";
        done

}

#If java starting process was incomplete it will stop all the instances
stop_started_java_app_if_required(){
    if [[ $IS_JAVA_SERVER_STARTED == "false" ]]; then
        for used_port in "${JAVA_INSTANCE_PORTS[@]}"
            do
                echo "Stoping Server from port ${used_port}";
                sudo -u uim_tomcat ./stop.sh --port ${used_port}
            done
        exit 2;
    fi

}

start_java_app(){
    echo "Creating #$JAVA_INSTANCE_COUNT Java instances";
    temp_instance_count=$JAVA_INSTANCE_COUNT;
    while [[ $temp_instance_count -gt 0 ]]
        do
            read -rp "Enter port :" port;
            if [[ ! "$port" ]]; then
                echo "No Port specified Using default 808$temp_instance_count";
                port="808"$temp_instance_count
            fi

            read -rp "Enter NIO port :" ni_port;
            if [[ ! "$ni_port" ]]; then
                echo "No NIO Port specified Using default 844$temp_instance_count";
                ni_port="844"$temp_instance_count;
            fi
            read -rp "Enter Enviornment to use[dev,prod,qa] :" env;
            if [[ ! "$env" ]]; then
                echo "No Enviornment specified using defualt prod";
                env="prod";
            fi
            sudo -u $MAIN_USER ./ec2javaappstart.sh -p $port -n $ni_port -e $env
            if [ $? -eq 0 ]; then
                JAVA_INSTANCE_PORTS[$temp_instance_count]=$port;
            elif [ $? -gt 0 ]; then
                echo "Not able to start the server based on the configuration provided Aborting the System"
                IS_JAVA_SERVER_STARTED=false;
                temp_instance_count=0;
            fi
            temp_instance_count=$((temp_instance_count-1));
        done
}

install_java_app(){
    read -rp "How Many Instance do you want to create?" JAVA_INSTANCE_COUNT;
    if [[ $JAVA_INSTANCE_COUNT -eq 0 ]]; then
        echo "Zero Instance is not a valid option, defaulting to 1";
        JAVA_INSTANCE_COUNT=1;
    fi
    start_java_app;
    stop_started_java_app_if_required;
    printServerAndIp;
}
#Clean up any data sets
clean_data_sets(){
    read -rp "Do you want a clean data install?(Y/N)" is_clean_install;
    shopt -s nocasematch;
    case "$is_clean_install" in
        y) echo "Doing a Data Clean..."; sudo ./drop_all_db.sh;;
        *) echo "Using The Exisitng Data";;
    esac
}

#Checks if all the pre requesties for this app is already installed or not
check_java_app_pre_req(){
    read -rp "Do you have all the pre-requesties installed?(Y/N)" PRE_REQ_CHCK;
    shopt -s nocasematch;
    case "$PRE_REQ_CHCK" in
        y) echo "Great Lets start Deploying App...";;
        *) echo "Please install All the pre requesties and re run this script to configure"; exit 1;;
    esac
}
configure_java_app(){
    echo "Processing Java Application Configuration"
    java_version_check;
    check_java_app_pre_req;
    clean_data_sets;
    install_java_app;
}

#Application installation
install_app(){
    echo "Application $BINARY_FILE_NAME is ready to install."
    if [[ "$PROJECT_TYPE" != "java" ]]; then
        echo "Currently Java application Set up only supported."
        echo "Please configure application manually."
        exit 1;
    else
        configure_java_app;
    fi
}

#Set up project in AWS
set_up_project(){
    echo "Starting project set up.";
    install_app;
}
#Moves the utility Scripts to the UIM/Script locations
move_utility_scripts(){

    if [ ! -d "$UTILITY_SCRIPT_LOC" ]; then
        sudo mkdir $UTILITY_SCRIPT_LOC;
    fi
    sudo mv -f $UTILITY_SCRIPT_NAME $UTILITY_SCRIPT_LOC/;
    sudo mv -f $UTILITY_SCRIPT_WORKER_NAME $UTILITY_SCRIPT_LOC/;
    sudo chmod 777 $UTILITY_SCRIPT_LOC/$UTILITY_SCRIPT_WORKER_NAME;
    sudo chmod 777 $UTILITY_SCRIPT_LOC/$UTILITY_SCRIPT_NAME;
    echo "Utility Scripts are placed at $UTILITY_SCRIPT_LOC/"

}
#Note the main User
note_main_user;
#call project set up to begin installation process
set_up_project;

#Moves the scripts for utility work
move_utility_scripts;

echo "Project $PROJECT_NAME deployment completed..."

sayBye;
exit 0;