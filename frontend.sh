#!/bin/bash

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

VALIDATE(){ # Functions receive arguments like normal scripts
    if [ $1 -ne 0 ]; then
        echo -e "Installing $2 ... $R FAILED $N" | tee -a $LOG_FILE
        exit 1 # Exit the script if installation failed with red color
    else
        echo -e "Installing $2 ... $G SUCCESSFUL $N" | tee -a $LOG_FILE # Print success message in green color
    fi 

}


###  frontend Application Installation Steps NodeJS Application ###
dnf module disable nginx -y &>>$LOG_FILE # Disable the default nginx module
dnf module enable nginx:1.24 -y &>>$LOG_FILE # Enable the nginx 1.24 module
dnf install nginx -y &>>$LOG_FILE # Install Nginx
VALIDATE $? "Installing Nginx"    # Validate the last command

systemctl enable nginx  &>>$LOG_FILE # Enable nginx service
systemctl start nginx   &>>$LOG_FILE # Start nginx service
VALIDATE $? "Starting Nginx Service"    # Validate the last command

rm -rf /usr/share/nginx/html/* 

curl -o /tmp/frontend.zip https://roboshop-artifacts.s3.amazonaws.com/frontend-v3.zip &>>$LOG_FILE # Download the application code

cd /usr/share/nginx/html 
unzip /tmp/frontend.zip &>>$LOG_FILE # Unzip the application code
VALIDATE $? "Downloading frontend Application Code"    # Validate the last command

rm -rf /etc/nginx/nginx.conf 
cp $SCRIPT_DIR/nginx.conf /etc/nginx/nginx.conf
VALIDATE $? "Copying Nginx Configuration File"    # Validate the last command

systemctl restart nginx # Restart Nginx
VALIDATE $? "Restarting Nginx Service"    # Validate the last command




