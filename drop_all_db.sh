#!/usr/bin/env bash


usage()
{

echo "Example ./drop_all_db.sh -p <port_num>  -h <host_name> -u <user_name> -s <password>
        
        port : Specifies the port to connect to , default to 57980
        host : specifies host to connect to, default to 127.0.0.1
        u    : Specifies user name for the data base
        s    : Specifies password for the data base

"

}


if [[ $1 == "-h" || $1 == --help ]]
then
  usage
else
while getopts ":h:p:u:s:" opt; 
do
  case $opt in
    h|--host) host=$OPTARG;;
    p|--port) port=$OPTARG;;
    u|--user) user=$OPTARG;;
    s|--pass) pass=$OPTARG;;
    \?) echo "Invalid option";
        exit 1;
        ;;
    
    :) echo "Option -$OPTARG requires an argument." >&2
       exit 1
       ;;
  esac
done

   if [[ $host == "" ]]
   then
      echo "no host, default connecting 127.0.0.1";
      export m_host="127.0.0.1";
   else
      export m_host=$host;
   fi


   if [[ $port == "" ]]
   then
      echo "no port, default 57980";
      export m_port=57890;
   else
      export m_port=$port;
   fi
 
   if [[ $user == "" ]] && [[ $pass == "" ]]
   then
      echo "mongo --quiet -h $m_host -p $m_port  "uim_location" --eval 'db.dropDatabase()'";
   else
      echo "-u <user> -s <pass> is mandatory"
      echo "mongo --quiet -h $m_host -p $m_port -u $user -s $pass  "uim_location" --eval 'db.dropDatabase()'";
   fi
fi

#mongo "uim_location" --eval "db.dropDatabase()"
#echo "mongo --quiet -h $m_host -p $m_port -u $user -s $pass  "uim_location" --eval 'db.dropDatabase()'"
