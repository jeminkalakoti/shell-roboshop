#!/bin/bash

USER_ID=$(id -u)
R='\e[0;31m' # Red
G='\e[0;32m' # Green
Y='\e[0;33m' # Yellow
N='\e[0m'    # No Color

LOGS_FOLDER="/var/log/shell-roboshop/"
SCRIPT_NAME=$( echo $0 | cut -d "." -f1 ) # Extract script name without extension
MONGODB_HOST="mongodb.kalakoti.fun" # MongoDB Host
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


###  Catalogue Application Installation Steps NodeJS Application ###

dnf module disable nodejs -y &>>$LOG_FILE # Disable the default nodejs module
VALIDATE $? "Disabling NodeJS module" # Validate the last command

dnf module enable nodejs:20 -y &>>$LOG_FILE # Enable the nodejs 20 module
VALIDATE $? "Enabling NodeJS 20 module" # Validate the last command

dnf install nodejs -y &>>$LOG_FILE # Install NodeJS
VALIDATE $? "Installing NodeJS"    # Validate the last command

useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE # Add application user
VALIDATE $? "Adding Application User"    # Validate the last command

mkdir /app # Create application directory
VALIDATE $? "Creating Application Directory"    # Validate the last command

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>>$LOG_FILE # Download the application code
VALIDATE $? "Downloading catalogue Application Code"    # Validate the last command

cd /app 
VALIDATE $? "Changing Directory to /app"    # Validate the last command

unzip /tmp/catalogue.zip &>>$LOG_FILE # Unzip the application code
VALIDATE $? "Unzipping catalogue Application Code"    # Validate the last command 

npm install &>>$LOG_FILE # Download the application dependencies
VALIDATE $? "Installing Application Dependencies"    # Validate the last command

cp catalogue.service /etc/systemd/system/catalogue.service # Copy the service file
VALIDATE $? "Copying Service File"    # Validate the last command

systemctl daemon-reload # Reload systemd to register the service
VALIDATE $? "Reloading SystemD"    # Validate the last command

systemctl enable catalogue &>>$LOG_FILE # Enable the service
VALIDATE $? "Enabling Catalogue Service"    # Validate the last command

systemctl start catalogue # Start the service
VALIDATE $? "Starting Catalogue Service"    # Validate the last command

cp mongo.repo /etc/yum.repos.d/mongo.repo # Copy the repo file
VALIDATE $? "Adding MongoDB Repo" # Validate the last command

dnf install mongodb-mongosh -y &>>$LOG_FILE # Install MongoDB Shell
VALIDATE $? "Installing MongoDB Shell"    # Validate the last command

mongosh --host $MONGODB_HOST </app/db/master-data.js &>>$LOG_FILE # Load the schema
VALIDATE $? "Loading Schema to MongoDB"    # Validate the last command

systemctl restart catalogue # Restart the service
VALIDATE $? "Restarting Catalogue Service"    # Validate the last command
