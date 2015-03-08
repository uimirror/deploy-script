#!/usr/bin/env bash
#set -xv

#***********************************************
#  Name: autodeploy.sh
#  Date: 11th Jan 2015
#  Usage: ./autodeploy.sh -r <git-repo-path> -b <branch> -u <user> -p <password>
#
#**********************************************

#To Show the message
# cp -rv ./autodeploy.sh /home/kumarprd
usage(){

    echo "Usage : $0 -p <project_type> -j <java_version> -r <repo> -b <branch>
    E.g. : ./autodeploy.sh -p java -j 1.8 -r uimirror/rtp.git -b devlop
    project_type: Specifies which type of Project it is, i.e [java, other], default is java
    java_version: If Project type is Java, which java version to use, default is 1.8
    repo : path too git repo (e.g. uimirror/rtp.git)
    branch : devlop OR master (default is devlop if not mentioned)"
}

#Prints Bye Message before closing the Script
sayBye(){
    echo "Bye!!!";
}

#Delete the Branch which was unsuccessful while installing
delete_unsuccess_branch(){
    cd $DEPLOY_SCRIPT_HOME/$TEMP_REPO
    repo_loc=$(ls);
    cd $repo_loc;
    echo "Now deleteing the remote $NEW_BRANCH branch because of unsuccessful install."
    echo "$(pwd)"
    git push origin --delete $NEW_BRANCH
    if [ $? -ne 0 ]; then
        echo "CRITICAL: Unable to delete branch $NEW_BRANCH"
        exit 12
    fi
}

#Prepares the deploye script with dynamic value substitue
prepare_deploy_script(){

    echo "Making Deploy Script to deploy on EC2 $ZIP_PATH/$EC2_DEPLOY_SCRIPT";

    sed -i.bak "s/^\(PROJECT_TYPE=\).*/\1${PROJECT_TYPE}/" $ZIP_PATH/$EC2_DEPLOY_SCRIPT

    sed -i.bak "s/^\(BINARY_FILE_NAME=\).*/\1${BINARY_FILE_NAME}/" $ZIP_PATH/$EC2_DEPLOY_SCRIPT

    sed -i.bak "s/^\(JAVA_VERSION=\).*/\1${JAVA_VERSION}/" $ZIP_PATH/$EC2_DEPLOY_SCRIPT

    # remove the Back up file
    rm -rf $ZIP_PATH/$EC2_DEPLOY_SCRIPT".bak";

    chmod 777 $ZIP_PATH/$EC2_DEPLOY_SCRIPT;

    echo "Deployment Descriptor for the EC2 Deployment is completed."

}

#prepeare ZIP to upload to aws
prepare_to_upload_aws(){
    echo "Preparing Distrubutions for AWS";
    if [[ "$PROJECT_TYPE" == "java" ]]; then
        ZIP_PATH=$GRADLE_BUILD_PATH/build/distributions;
        BINARY_FILE_NAME=$PROJECT_NAME.$NEW_BRANCH.zip;
        mv "$ZIP_PATH/$PROJECT_NAME.zip" "$ZIP_PATH/$BINARY_FILE_NAME";
        if [ $? -ne 0 ]; then
            echo "CRITICAL: Unable to rename binary $BINARY_FILE_NAME on path $ZIP_PATH"
            delete_unsuccess_branch;
            exit 12
        fi
        echo "Adding deploy script to binary";
        cp $DEPLOY_SCRIPT_HOME/$EC2_DEPLOY_SCRIPT $ZIP_PATH;
        prepare_deploy_script;
        zip -u -j $ZIP_PATH/$BINARY_FILE_NAME $ZIP_PATH/$EC2_DEPLOY_SCRIPT;
        if [ $? -ne 0 ]; then
            echo "CRITICAL: Unable to add EC2 Deploy Script to binary $BINARY_FILE_NAME on path $ZIP_PATH"
            delete_unsuccess_branch;
            exit 12
        fi
    else
        cd $DEPLOY_SCRIPT_HOME/$TEMP_REPO;
        ZIP_PATH=$DEPLOY_SCRIPT_HOME/$TEMP_REPO;
        project_name=$(ls);
        cp $DEPLOY_SCRIPT_HOME/$EC2_DEPLOY_SCRIPT .;
        BINARY_FILE_NAME=$project_name.$NEW_BRANCH.zip;
        prepare_deploy_script;
        zip -r $BINARY_FILE_NAME .;
        if [ $? -ne 0 ]; then
            echo "CRITICAL: Unable to create binary for the project $project_name."
            delete_unsuccess_branch;
            exit 12
        fi
    fi

    echo "Created the Binary with name $BINARY_FILE_NAME in $ZIP_PATH";

}

#Grant Sudo access to the destination
grant_access_destination(){
    ssh -i $EC2_SECURITY_KEY $EC2_USER_ID@$EC2_IP "sudo chown -R jayaram:jayaram $EC2_DEPLOYMENT_LOC"
    echo "Granted permision to $EC2_DEPLOYMENT_LOC"

}

#Copy the binary to AWS
copy_binary_to_aws(){
    prepare_to_upload_aws;
    echo -e "\n Pushing build file to EC2....\n";

        delete_unsuccess_branch;
    read -rp "Enter IP or Public DNS of EC2 instance :" EC2_IP
    read -rp "Give path to the ec2 security key :" EC2_SECURITY_KEY
    read -rp "Give full path in the ec2 to which file will be copied :" EC2_DEPLOYMENT_LOC
    read -rp "Enter username to connect to ec2 instance :" EC2_USER_ID

    if type -p scp; then
        echo "Found SCP to copy binary";
        scp -i $EC2_SECURITY_KEY $ZIP_PATH/$BINARY_FILE_NAME $EC2_USER_ID@$EC2_IP:$EC2_DEPLOYMENT_LOC;
        if [ $? -eq 1 ]; then
            echo "No permision to upload to the detination ${EC2_DEPLOYMENT_LOC}"
            grant_access_destination;
            scp -i $EC2_SECURITY_KEY $ZIP_PATH/$BINARY_FILE_NAME $EC2_USER_ID@$EC2_IP:$EC2_DEPLOYMENT_LOC;
        fi
        if [ $? -ne 0 ]; then
            echo "CRITICAL: Failed to scp ${BINARY_FILE_NAME} to dest ${EC2_DEPLOYMENT_LOC}."
            delete_unsuccess_branch;
            exit 12
        fi
    else
        echo "Can't copy to remote location, as SCP not found";sayBye;delete_unsuccess_branch;exit 12
    fi
}

#This will Create Zip, upload and intsall into aws
install_in_aws(){
    echo "Application Installation process started";
    copy_binary_to_aws;
    delete_unsuccess_branch;

    echo -e "\n\n Now you will be logged in to ec2 instance.. Follow below instructions.."
    echo -e "\n In ec2 terminal run the below commands step by step."
    echo -e "\n cd $(echo $EC2_DEPLOYMENT_LOC)"
    echo -e "\n Now use sudo to execute the script ec2_works.sh, e.g. sudo ./ec2_works.sh\n"

    ssh -i $EC2_SECURITY_KEY $EC2_USER_ID@$EC2_IP "cd $EC2_DEPLOYMENT_LOC"

}

#Guess the next Branch Number
guess_new_branch_name(){
    OIFS=$IFS;
    IFS=" ";
    max=-1;
    branches="$1";
    prfix="v";
    branchRegex="/($prfix)[0-9]+";
    branchNumRegex="[0-9]+";
    for x in $branches
        do
            if [[ $x =~ $branchRegex ]]; then
                temp=${BASH_REMATCH[0]};
                if [[ $temp =~ $branchNumRegex ]]; then
                    tempNum=${BASH_REMATCH[0]};
                    if [[ "$tempNum" > "$max" ]]; then
                        max="$tempNum";
                    fi
                fi
            fi
        done
    IFS=$OIFS;
    nextBNumber=$((max + 1));
    NEW_BRANCH=$prfix$nextBNumber;
    echo "I guess Next Branch will be $NEW_BRANCH";
}

git_push_new_branch(){
    echo "Trying to create a new branch for $REPO";
    availableBranches=$($GIT_PATH branch -r);
    echo -e "\nCurrently Below branches found on git...$availableBranches";
    guess_new_branch_name "$availableBranches";
    echo -e "\n Now pushing $NEW_BRANCH branch to git....";
    $GIT_PATH checkout -b $NEW_BRANCH;
    $GIT_PATH push origin $NEW_BRANCH;

}


#Find or Set the project's Gradle Path
set_project_gradle_path(){
    #Find Repo Name
    repo_name=$(echo $REPO | rev |cut -f 1 -d "/" |rev |cut -f 1 -d ".")
    dir_count=$(ls -l $(echo -e $repo_name)/ | grep ^d | wc -l)
    if [[ $dir_count -gt 1 ]]; then
        echo -e "\nMultiple project found in ./$TEMP_REPO/$(echo $repo_name) , Choose one from below...\n"
        echo -e "\e[5m$(find $(pwd)/$repo_name -maxdepth 1 -type d|sed 1,2d)\n";
        read -rp "Enter the project path to be deployed :" GRADLE_BUILD_PATH;
    else
        PROJECT_NAME=$(ls -l $(pwd)/$repo_name |grep  ^d|awk '{print $9}')
        GRADLE_BUILD_PATH="$(pwd)/$repo_name/$PROJECT_NAME"
    fi

}

#Build Project, currently only gradle project can be build
build_project(){

    if [[ "$PROJECT_TYPE" != "java" ]]; then
        repo_loc=$(ls);
        cd $repo_loc;
        echo "No Project Build Required, as its not a java project"
        return 1;
    fi
    set_project_gradle_path;
    echo "Warming to start Build for the Gradle project: $PROJECT_NAME";
    if [[ ! "$GRADLE_BUILD_PATH" ]]; then echo "Gradle Build Path $GRADLE_BUILD_PATH is invalid."; sayBye; exit 12; fi
    temp_loc=$(pwd);
    cd $GRADLE_BUILD_PATH;
    ./gradlew build distZIp;
    echo "$PROJECT_NAME, Build Completed";
    #Move Back to the main repo location
    cd $temp_loc;
    repo_loc=$(ls);
    cd $repo_loc;
}

#Take GIT Credentials From User
readGitCredentials(){
    attempt=0;
    read -p "Enter your GitHub Id :" userId;
    if [[ ! "$userId" ]]; then
        echo "Invalid GitHub Id";
        sayBye;
        exit 12;
    fi
    while [[ $attempt -lt 3 ]]
        do
            read -s -p "Enter Password for $userId :" password;
            echo -n;
            if [[ ! "$password" ]]; then
                attempt=$((attempt + 1));
            else
                attempt=4;
            fi
        done
    if [[ ! "$password" ]]; then
        echo "Invalid GitHub Credentials!!! Attemp Excedded...";
        sayBye;
        exit 12;
    fi

    GIT_CRED="$userId:$password";

}

#Clone The Repository using Git
git_repo_clone(){
    echo "\nCloning Branch: $BRANCH from $REPO";
    [[ -e ./$TEMP_REPO ]] && rm -rf ./$TEMP_REPO
    mkdir ./$TEMP_REPO ; cd ./$TEMP_REPO
    readGitCredentials;
    $GIT_PATH clone -b $BRANCH https://$GIT_CRED@github.com/$REPO
    if [[ $? -eq 0 ]]; then
        echo "Git Clone Completed...";
    else
        echo "git Clone error, exiting"; sayBye; exit 128;
    fi

#cd .. && rm -rf ./temp_git
}

#Find or Set the Git Path
find_and_set_git_path(){
    echo "Checking Git on your System";
    if type -p git; then
        echo "Found Git On your System";
        GIT_PATH=git;
    else
        read -rp "Git Not found, Please enter the path for git: " GIT_PATH;
        [[ -e "$GIT_PATH" ]] || echo "wrong GIT Path";sayBye; exit 12
    fi
    #git_pull_count_dir $1 $2 $3 $4 $GIT_PATH
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
        exit 12;
    fi

    if [[ "$_java" ]]; then
        version=$("$_java" -version 2>&1 | awk -F '"' '/version/ {print $2}')
        echo "Found Java version $version"
        if [[ "$version" > "$1" ]]; then
            echo "Perfect Found Required Java Version.";
        else
            echo "Java version is less than $1 , Please Upgrade Java and try again."
            sayBye;
            exit 12;
        fi
    fi
}


if [[ $1 == "-h" || $1 == --help || $1 == "-help" ]]; then
    usage;
fi
#Default project type is java
PROJECT_TYPE='java';
JAVA_VERSION="1.8";
DEPLOY_SCRIPT_HOME=$(pwd);
TEMP_REPO="temp_repo";
EC2_DEPLOY_SCRIPT="ec2deploy.sh";
while getopts ":p:j:r:b:" opt;
    do
        case $opt in
        r) REPO=$OPTARG;;
        b) BRANCH=$OPTARG;;
        j) JAVA_VERSION=$OPTARG;;
        p) PROJECT_TYPE='other';;
        \?) echo "Invalid options."; usage ;sayBye;
        exit 1;
        ;;

        #:) echo "Option -$OPTARG requires an argument." >&2
        #           exit 1
        #           ;;
        esac
    done

echo "Hello...Starting Auto Deployment....";
#Now Check for the Repository, branch and clone the same
if [[ ! "$REPO" ]]; then echo "No Reposoitry Specified." ; usage ; sayBye; exit 12; fi
if [[ ! "$BRANCH" ]]; then BRANCH="devlop"; fi

echo "Project Type: $PROJECT_TYPE";

if [[ "$PROJECT_TYPE" == "java" ]]; then
    java_version_check $JAVA_VERSION;
fi

#Now Check Git, and set the Git Path
find_and_set_git_path;

#Clone Repository
git_repo_clone;

#Build Project if its of type java, default building is gradle
build_project;

#Now Push the code to the new branch
git_push_new_branch;

#Now Install in AWS
install_in_aws
