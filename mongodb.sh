#!/bin/bash

USER_ID=$(id -u)
R='\e[0;31m' # Red
G='\e[0;32m' # Green
Y='\e[0;33m' # Yellow
N='\e[0m'    # No Color

LOGS_FOLDER="/var/log/shell-roboshop/"
SCRIPT_NAME=$( echo $0 | cut -d "." -f1 ) # Extract script name without extension
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log" # Define log file path

# -e enables the interpretation of backslash escapes

mkdir -p $LOGS_FOLDER # Create logs folder if not exists
echo "Script started and executed at : $(date)" | tee -a $LOG_FILE # Log script start time

if [ $USER_ID -ne 0 ]; then
    echo -e "$R ERROR $N:: You must have a root privilege to install packages" 
    exit 1 # Exit the script if not root
fi

VALIDATE(){ # Functions receive arguments like normal scripts
    if [ $1 -ne 0 ]; then
        echo -e "Installing $2 ... $R FAILED $N" | tee -a $LOG_FILE
        exit 1 # Exit the script if installation failed with red color
    else
        echo -e "Installing $2 ... $G SUCCESSFUL $N" | tee -a $LOG_FILE # Print success message in green color
    fi 

}

cp mongo.repo /etc/yum.repos.d/mongo.repo # Copy the repo file
VALIDATE $? "Adding MongoDB Repo" # Validate the last command

dnf install mongodb-org -y &>>LOG_FILE # Install MongoDB
VALIDATE $? "Installing MongoDB"    # Validate the last command

systemctl enable mongod &>>$LOG_FILE # Enable MongoDB service
VALIDATE $? "Enabling MongoDB"    # Validate the last command

systemctl start mongod &>>$LOG_FILE # Start MongoDB service
VALIDATE $? "Starting MongoDB"    # Validate the last command

sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mongod.conf
VALIDATE $? "Allowing remote connections to MongoDB"

systemctl restart mongod
VALIDATE $? "Restarted MongoDB"