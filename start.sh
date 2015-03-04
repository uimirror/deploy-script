#!/usr/bin/env bash

#***********************************************
#  Name: start.sh
#  Date: 9 Nov 2014
#  Usage: ./start.sh -port=8080 -nioport=8443 -env=prod
#
#**********************************************

#To Show the message
usage(){

  echo "Usage : $0 -p <port_to_start> -n <nioport> -e <env>
        port_to_start : Tomcat to start on this port, default 8080
        nioport : shutdown port
        env :  prod OR dev", default prod

}

port_usage()
{
   
       port_check=$(nc -z localhost $(echo $1) > /dev/null;echo $?) 
      # echo $port_check;
       [[ $port_check -ne "0" ]] && return 1 || return 0

}

if [[ $1 == "-h" || $1 == --help ]]
then
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

   if [[ $port == "" ]]
   then
       echo "no port $port, using 8080"
       port=8080
       if ( port_usage "$port" )
       then
          echo "$port is used"
          exit 2;
       else
          export tomcat_port=$port
       fi
   else
       port=$port
       if ( port_usage "$port" )
       then
          echo "$port is used"
          exit 2;
       else
          export tomcat_port=$port
       fi
   fi


#  echo $nioport
  if [[ $nioport == "" ]]
  then
     echo "no nioport, using 8443"
     export nio_port=8443;
  else
     export nio_port=$nioport;
  fi

  if [[ $env == "" ]]
  then
      echo "no env mentioned, using prod"
      export use_env=prod;
  else
      export use_env=$env;
  fi
      
JAVA_OPTS='("-Denv=$use_env" "-Dport=$tomcat_port" "-Dnioport=$nio_port")'  ../bin/reach-web-conf &


echo "$port:$!" >> /var/run/uimirror.pid

fi
   
  
#JAVA_OPTS='-Denv=prod' -port=$port ../bin/location-endpoint &

#echo "$port :  $!" >> /tmp/uimirror.pid     
    
