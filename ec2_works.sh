#!/usr/bin/env bash
BUILD_PATH=/home/khitish/build
BUILD_FILE=uim-reach-web.v7.zip





####script copied with build file#######




go_to_build(){

  cd $BUILD_PATH &&  unzip $BUILD_FILE
  rm -rf $BUILD_PATH/*.zip
  PR_DIR=$(echo $BUILD_FILE | awk -F. '{print $1}')
  
  read -rp "Do you want clean deploy . (Y|N)" RES
  if [[ $RES == "Y" ]]; 
  then
      cd "$BUILD_PATH/$PR_DIR/scripts" ; echo "Cleaning mongo database" ; ./drop_all_db.sh ; ./start.sh
  else
      cd "$BUILD_PATH/$PR_DIR/scripts" ; ./start.sh
  fi
  

}



java_v18_check(){


java -version 2>&1 |awk '/version/{print $NF}' |grep "1.8" >& /dev/null
[[ $? == "0" ]] && go_to_build || echo "Java 1.8 required, Please upgrade your java"; exit 12;  

}

java_v18_check
