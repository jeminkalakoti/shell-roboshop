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

###  MySQL Installation Steps ###
dnf install mysql-server -y &>>$LOG_FILE # Install MySQL
VALIDATE $? "Installing MySQL"    # Validate the last command

systemctl enable mysqld &>>$LOG_FILE # Enable MySQL service
VALIDATE $? "Enabling MySQL"    # Validate the last command

systemctl start mysqld &>>$LOG_FILE # Start MySQL service
VALIDATE $? "Starting MySQL"    # Validate the last command

mysql_secure_installation --set-root-pass RoboShop@1 &>>$LOG_FILE # Set the root password
VALIDATE $? "Setting MySQL Root Password"    # Validate the last command

END_TIME=$(date +%s) # Get the script end time
TOTAL_TIME=$((END_TIME - START_TIME)) # Calculate the total time taken
echo -e "Total time taken to execute the script:$Y $TOTAL_TIME seconds $N"

