#!/bin/bash

USER_ID=$(id -u)
R='\e[0;31m' # Red
G='\e[0;32m' # Green
Y='\e[0;33m' # Yellow
N='\e[0m'    # No Color

LOGS_FOLDER="/var/log/shell-roboshop/"
SCRIPT_NAME=$( echo $0 | cut -d "." -f1 ) # Extract script name without extension
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log" # Define log file path
START_TIME=$(date +%s) # Get the script start time

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

## Redis Installation Steps ##

dnf module disable redis -y &>>$LOG_FILE # Disable the default redis module
VALIDATE $? "Disabling Redis module" # Validate the last command

dnf module enable redis:7 -y &>>$LOG_FILE # Enable the redis 7 module
VALIDATE $? "Enabling Redis 7 module" # Validate the last command

dnf install redis -y &>>$LOG_FILE # Install Redis
VALIDATE $? "Installing Redis 7"    # Validate the last command

# Update the redis configuration to allow remote connections
sed -i -e 's/127.0.0.1/0.0.0.0/g' -e '/protected-mode/ c protected-mode no' /etc/redis/redis.conf
VALIDATE $? "Updating Redis Configuration by allowing remote connections"    # Validate the last command

systemctl enable redis &>>$LOG_FILE # Enable Redis service
VALIDATE $? "Enabling Redis"    # Validate the last command

systemctl start redis &>>$LOG_FILE # Start Redis service
VALIDATE $? "Starting Redis"    # Validate the last command 

END_TIME=$(date +%s) # Get the script end time
TOTAL_TIME=$((END_TIME - START_TIME)) # Calculate the total time taken
echo -e "Total time taken to execute the script:$Y $TOTAL_TIME seconds $N" 