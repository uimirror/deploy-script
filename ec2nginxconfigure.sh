#!/usr/bin/env bash
#set -xv
#**********************************
#   Name: ec2nginxconfigure.sh
#   Date: 09th March 2015
#   Usage sudo ./ec2nginxconfigure.sh -p <ports>
#   Here Ports are comma seperated port numbers;
#   i.e sudo ./ec2nginxconfigure.sh -p 8080,8181
#   Return Codes: 0- Sucessful execution
#                 1- In case of configuration error
#                 2- In case Invalid Argument
#                 3- Nginx Not found
#
#
#   Ths script currently not in use as not yet decided when a server is down who will remove that node
#**********************************

usage(){
        echo "Usage : $0 -p <ports>
        E.g. : $0 -p 8080,8181"
}

sayBye(){
    echo "Bye!!!";
}

#Converts the incomming port string to array
convert_port_str_to_array(){
    OIFS=$IFS;
    IFS=",";
    PORTS=($PORTS_STR);
    IFS=$OIFS;
}

#Checks the nginx command from the system, else takes the user provided path for nginx
nginx_path_check_or_set(){
    echo "Checking the NGINX installation in the system."
    if type -p $NGINX; then
        echo "found $NGINX executable in PATH"
    else
        echo "No $NGINX found in the System PATH.";
        echo "Please have the installation and re run this script."
        sayBye;
        exit 3;
    fi

    read -rp "I assume your configuration file resides at: $CONFIGURATION_LOC, Please confirm? (Y/N)" config_loc_conf;
    shopt -s nocasematch;
    case "$config_loc_conf" in
        y) echo "Great my assumption is right...";;
        *) read -rp "Please give the configuration location" CONFIGURATION_LOC;
            if [ ! -d "$CONFIGURATION_LOC" ]; then
                echo "Sorry, Mentioned Path is incorrect";
                sayBye;
                exit 3;
            fi
        ;;
    esac
}

configure_from_template(){
    echo "test";
}

update_existing_configuration(){
    read -rp "Help me with the configuration file name" CONFIGURATION_FILE;
    if [[ ! "$CONFIGURATION_FILE" ]]; then
        echo "Please enter a valid existing configuration file name";
        read -rp "Help me with the configuration file name" CONFIGURATION_FILE;
        if [[ ! "$CONFIGURATION_FILE" ]]; then
            echo "Sorry Maximum try completed.";
            sayBye;
            exit 3;
        fi
    fi
    sudo sed -i.back -e '/^server {/,/^}/{/^}/i\    inserted text line 1\n    inserted text line 2' -e '}' $CONFIGURATION_LOC$CONFIGURATION_FILE


}

configure_web_server(){
    shopt -s nocasematch;
    read -rp "Do you want to update the Web Server Configuration?(Y/N)" IS_WEB_SERVER_CONFIGURATION;
    case "$IS_NEW_CONFIGURATION" in
        y) echo "Okay, Make sure you have a base configuration ...";configure_from_template;;
        *) echo "Okay, Lets Update your existing configuration";update_existing_configuration;;
    esac
    read -rp "Do you want new server configuration?(Y/N)" IS_NEW_CONFIGURATION;



}

CONFIGURATION_LOC="/etc/nginx/conf.d/"
NGINX="nginx"
while getopts ":p:" opt;
    do
        case $opt in
            p) PORTS_STR=$OPTARG;;
            \?) echo "Invalid options."; usage ;sayBye;
                exit 1;
                ;;
        esac
    done

echo "Hello Starting the NGINX Configuration";
#Now Check for the Repository, branch and clone the same
if [[ ! "$PORTS_STR" ]]; then
    echo "No Ports Specified." ; usage ; sayBye; exit 2;
else
    convert_port_str_to_array;
fi

#Check the NGINX set up
nginx_path_check_or_set;

#Now Configure the application
configure_web_server;