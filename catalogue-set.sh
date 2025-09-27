#!/bin/bash

set -euo pipefail # Exit on error, undefined variable, and error in a pipeline
# set -e
# set -u
# set -o pipefail   

trap 'echo "There is an error in $LINENO, Command is: $BASH_COMMAND"' ERR # Trap ERR signal and print the line number and command that caused the error


USER_ID=$(id -u)
R='\e[0;31m' # Red
G='\e[0;32m' # Green
Y='\e[0;33m' # Yellow
N='\e[0m'    # No Color

LOGS_FOLDER="/var/log/shell-roboshop/"
SCRIPT_NAME=$( echo $0 | cut -d "." -f1 ) # Extract script name without extension
SCRIPT_DIR=$PWD # Get the current working directory
MONGODB_HOST="mongodb.kalakoti.fun" # MongoDB Host
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log" # Define log file path

# -e enables the interpretation of backslash escapes

mkdir -p $LOGS_FOLDER # Create logs folder if not exists
echo "Script started and executed at : $(date)" | tee -a $LOG_FILE # Log script start time

if [ $USER_ID -ne 0 ]; then
    echo -e "$R ERROR $N:: You must have a root privilege to install packages" 
    exit 1 # Exit the script if not root
fi


###  Catalogue Application Installation Steps NodeJS Application ###

dnf module disable nodejs -y &>>$LOG_FILE # Disable the default nodejs module
dnf module enable nodejs:20 -y &>>$LOG_FILE # Enable the nodejs 20 module
dnf install nodejs -y &>>$LOG_FILE # Install NodeJS
echo -e "Installing NodeJS:20 ... $G SUCCESSFUL $N"   # Print success message in green color

id roboshop &>>$LOG_FILE # Check if the user already exists
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE # Add application user
else
    echo -e "User roboshop already exists. $Y SKIPPING $N" # Print skipping message in yellow color
fi

mkdir -p /app #Create application directory if not exists 
curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>>$LOG_FILE # Download the application code
cd /app 
rm -rf /app/* # Remove any existing application code
unzip /tmp/catalogue.zip &>>$LOG_FILE # Unzip the application code
npm install &>>$LOG_FILE # Download the application dependencies
cp $SCRIPT_DIR/catalogue.service /etc/systemd/system/catalogue.service # Copy the service file
systemctl daemon-reload # Reload systemd to register the service
systemctl enable catalogue &>>$LOG_FILE # Enable the service
systemctl start catalogue # Start the service
echo -e "catalogue application setup completed ... $G SUCCESSFUL $N"   # Print success message in green color

cp $SCRIPT_DIR/mongo.repo /etc/yum.repos.d/mongo.repo # Copy the repo file
dnf install mongodb-mongosh -y &>>$LOG_FILE # Install MongoDB Shell

INDEX=$(mongosh mongodb.kalakoti.fun --quiet --eval "db.getMongo().getDBNames().indexOf('catalogue')")
if [ $INDEX -le 0 ]; then
    mongosh --host $MONGODB_HOST </app/db/master-data.js &>>$LOG_FILE # Load the schema
    VALIDATE $? "Loading Catalogue Products to MongoDB"    # Validate the last command
else
    echo -e "Catalogue Products already exists. $Y SKIPPING $N" # Print skipping message in yellow color
fi  

systemctl restart catalogue # Restart the service
echo -e "Loading Prodcuts and Restarting catalogue service ... $G SUCCESSFUL $N"   # Print success message in green color