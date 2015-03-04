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

echo "Usage : $0 -r <repo> -b <branch> -u <user> -p <pass>
E.g. : ./autodeploy.sh -r uimirror/rtp.git -b devlop -u kumarprd -p xxx
repo : path too git repo (e.g. uimirror/rtp.git)
branch : devlop OR master (default is devlop if not mentioned)
user : github user authentication
pass : password for logging in github"

}


operation_in_aws(){

key=$1;
build_file=$2;
user=$3;
EC2=$4;

export cd_path=$ec2p;


echo -e "\n\n Now you will be logged in to ec2 instance.. Follow below instructions.."
echo -e "\n In ec2 terminal run the below commands step by step."
echo -e "\n cd $(echo $cd_path)"
echo -e "\n Now use sudo to execute the script ec2_works.sh, e.g. sudo ./ec2_works.sh\n"

ssh -i $key $user@$EC2

}

#operation_in_aws

upload_aws(){

proj_path="$1";
name="$2";
file_name=$(echo $proj_path |rev |cut -d/ -f1 |rev);
zip_path="$(echo -e $proj_path)/build/distributions";
ec2_script="../../ec2_works.sh";

mv "$zip_path/$file_name.zip" "$zip_path/$file_name.$name.zip";
build_file_path="$zip_path/$file_name.$name.zip";
build_file="$file_name.$name.zip";

echo -e "\n Pushing build file to EC2....\n";


read -rp "Enter IP or Public DNS of EC2 instance :" EC2
read -rp "Give path to the ec2 security key :" key
read -rp "Give full path in the ec2 to which file will be copied :" ec2p
read -rp "Enter username to connect to ec2 instance :" user
#read -rp "Provide password to connect ec2 : " -s $pass


sed -i '/BUILD_PATH=/d' $ec2_script
sed -i "2 i\BUILD_PATH=$ec2p" $ec2_script

sed -i '/BUILD_FILE=/d' $ec2_script
sed -i "3 i\BUILD_FILE=$build_file" $ec2_script

which scp >& /dev/null
if [[ $? -eq "0" ]]; then
scp -i $key $build_file_path $ec2_script $user@$EC2:$ec2p
fi
operation_in_aws $key $build_file $user $EC2 $ec2p

}

#Build and push to new Branch
gradle_comp_git_checkout(){

git_path="$2";
grad_path="$1";
repo="$3";
branchPrefix="v";#make it customizable
if [[ "Y"$grad_path != "Y" ]];then  cd $grad_path ;./gradlew build distZIp; else echo -e "\e[31m No gradlew path"; exit 12; fi
cd .. && echo -e "\nBuild of $repo done ..." ; echo -e "\nBelow branches found on git...";
availableBranches=$($git_path branch -r);
#Call to get the next Branch Sequence
guessBranchName "$availableBranches" "$branchPrefix";
nextBranchSeq=$?;
$branchPrefix+=$nextBranchSeq;

new_branch =$branchPrefix;
echo -e "\n" $new_branch
echo -e "\n Now pushing $new_branch branch to git...."
$git_path checkout -b $new_branch
$git_path push origin $new_branch

#Call to upload to AWS
upload_aws $grad_path $NEW_BRANCH
}
#Guess the next Branch Number
guessBranchName(){
OIFS=$IFS;
IFS=" ";
max=-1;
branches="$1";
prfix="$2";
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
return "$nextBNumber";
}

git_pull_count_dir(){

git_path="$5";
branch="$2";
user="$3";
pass="$4";
repo="$1";
[[ -e ./temp_git ]] && rm -rf ./temp_git
mkdir ./temp_git ; cd ./temp_git
gitCred=$( readGitCredentials );
echo $gitCred;
echo $git_path;
git clone -b $branch https://$gitCred@github.com/$repo
if [[ $? -eq 0 ]]; then
repo_name=$(echo $repo | rev |cut -f 1 -d "/" |rev |cut -f 1 -d ".")
dir_count=$(ls -l $(echo -e $repo_name)/ | grep ^d | wc -l)
if [[ $dir_count -gt 1 ]]; then
echo -e "\nMultiple repo path found in ./temp_git/$(echo $repo_name) , Choose one from below...\n"
echo -e "\e[5m$(find $(pwd)/$repo_name -maxdepth 1 -type d|sed 1,2d)\n";
read -rp "Enter the correct path to gradle binary :" GRADLE_PATH;
else
proj_name=$(ls -l $(pwd)/$repo_name |grep  ^d|awk '{print $9}')
GRADLE_PATH="$(pwd)/$repo_name/$proj_name"
fi


if [[ "X"$GRADLE_PATH != "X" ]];then gradle_comp_git_checkout  $GRADLE_PATH $git_path $repo_name; else echo -e "\e[31m No gradlew path"; exit 12; fi
else
echo "git pull error, exiting";  exit 128;
fi

#cd .. && rm -rf ./temp_git
}

readGitCredentials(){
attempt=0;
read -p "Enter your GitHub Id :" userId;
if [[ ! "$userId" ]]; then
echo "You Should Enter your GitHub Id";
exit 12;
fi
while [[ $attempt -lt 3 ]]
do
read -s -p "Enter Password for $userId :" password;
echo -n;
echo $password;
if [[ ! "$password" ]]; then
attempt=$((attempt + 1));
else
attempt=4;
fi
done
if [[ ! "$password" ]]; then
echo "Attemp Excedded";
exit 1;
fi

cred="$userId:$password";
echo "$cred"
}

git_path(){
which git >& /dev/null
if [[ $? -eq "0" ]]; then
GIT_PATH=$(which git);
else
read -rp "Seems GIT is not installed, please enter the path to git binary: " GIT_PATH;
[[ -e "$GIT_PATH" ]] && export GIT_PATH=$GIT_PATH || echo "wrong GIT Path"; exit 12
fi

git_pull_count_dir $1 $2 $3 $4 $GIT_PATH
}


if [[ $1 == "-h" || $1 == --help ]]; then
usage
else
while getopts ":r:b:u:p:" opt;
do
case $opt in
r|--repo) repo=$OPTARG;;
b) branch=$OPTARG;;
u) user=$OPTARG;;
p) pass=$OPTARG;;
\?) echo "Invalid option";
exit 1;
;;

:) echo "Option -$OPTARG requires an argument." >&2
exit 1
;;
esac
done

if [[ $repo == "" ]]; then echo "No repo mentioned" ; usage ; exit 12; else repo=$repo; fi
if [[ $branch == "" ]]; then export branch="devlop"; else export $branch; fi


java_v18_check(){
java -version 2>&1 |awk '/version/{print $NF}' |grep "1.8" >& /dev/null
[[ $? == "0" ]] && git_path $repo $branch $user $pass || echo "Java 1.8 required, Please upgrade your java"; exit 12;

}
java_v18_check
fi
