#!/bin/bash

USER_ID=$(id -u)
R='\e[0;31m' # Red
G='\e[0;32m' # Green
Y='\e[0;33m' # Yellow
N='\e[0m'    # No Color

LOGS_FOLDER="/var/log/shell-roboshop/" # Create logs folder if not exists
SCRIPT_NAME=$( echo $0 | cut -d "." -f1 ) # Extract script name without extension
SCRIPT_DIR=$PWD # Get the current working directory
MONGODB_HOST="mongodb.kalakoti.fun" # MongoDB Host
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log" # Define log file path
MYSQL_HOST="mysql.kalakoti.fun" # MySQL Host

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

dnf install maven -y &>>$LOG_FILE # Install Maven
VALIDATE $? "Installing Maven"    # Validate the last command

id roboshop &>>LOG_FILE # Check if the cart already exists
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system cart" roboshop &>>$LOG_FILE # Add application cart
    VALIDATE $? "Creating system cart"    # Validate the last command
else
    echo -e "shipping roboshop already exists. $Y SKIPPING $N" # Print skipping message in yellow color
fi

mkdir -p /app #Create application directory if not exists 
VALIDATE $? "Creating Application Directory"    # Validate the last command

curl -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip &>>$LOG_FILE # Download the application code
VALIDATE $? "Downloading shipping Application Code"    # Validate the last command

cd /app 
VALIDATE $? "Changing Directory to /app"    # Validate the last command

rm -rf /app/* # Remove any existing application code
VALIDATE $? "Removing the existing Application Code"    # Validate the last command

unzip /tmp/shipping.zip &>>$LOG_FILE # Unzip the application code
VALIDATE $? "Unzipping shipping Application Code"    # Validate the last command 

mvn clean package  &>>$LOG_FILE # Build the application code
VALIDATE $? "Building shipping Application Code"    # Validate the last command

mv target/shipping-1.0.jar shipping.jar  &>>$LOG_FILE # Rename the jar file
VALIDATE $? "Renaming shipping Application Code"    # Validate the last command

cp $SCRIPT_DIR/shipping.service /etc/systemd/system/shipping.service # Copy the service file
VALIDATE $? "Copying Service File"    # Validate the last command

systemctl daemon-reload # Reload systemd to register the service
VALIDATE $? "Reloading SystemD"    # Validate the last command

systemctl enable shipping &>>$LOG_FILE # Enable the service
VALIDATE $? "Enabling shipping Service"    # Validate the last command

systemctl start shipping # Start the service
VALIDATE $? "Starting shipping Service"    # Validate the last command

dnf install mysql -y &>>$LOG_FILE # Install MySQL Client
VALIDATE $? "Installing MySQL Client"    # Validate the last command

mysql -h $MYSQL_HOST -uroot -pRoboShop@1 -e 'use cities' &>>$LOG_FILE # Check if the DB already exists
if [ $? -ne 0 ]; then
    mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/schema.sql &>>$LOG_FILE # Load the schema
    mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/app-user.sql &>>$LOG_FILE # Load the schema
    mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/master-data.sql &>>$LOG_FILE # Load the schema
    exit 1 # Exit the script if MySQL connection failed
else
    echo -e "Shipping data is already loaded ... $G SUCCESSFUL $N"
fi


systemctl restart shipping # Restart the service
VALIDATE $? "Restarting shipping Service"    # Validate the last command



