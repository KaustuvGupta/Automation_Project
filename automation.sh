#!/bin/bash
#Author			: Kaustuv Gupta
#Creation Date  	: 27/05/2023
#Version		: Automation-v0.2
#Change Variable 	: s3_bucket,myname in the VARABLE DECLARATION section
#--------------------------------------------------------------------------------------------------------------
#############################				 VARABLE DECLARATION		   		  #############################

echo "Variable Declaration >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
#update the following variables
s3_bucket="######"
myname="######"

timestamp=$(date '+%d%m%Y-%H%M%S')
tarfilename=${myname}-httpd-logs-${timestamp}.tar
inv_filename="/var/www/html/inventory.html"
cron_filename="/etc/cron.d/automation"
cron_job_schedule="5 10 * * * root bash /root/Automation_Project/automation.sh"

echo ">>Bucket Name: ${s3_bucket}"
echo ">>My Name: ${myname}"
echo ">>TimeStamp: ${timestamp}"
echo ">>Html file path: ${inv_filename}"
echo ">>Cronjob file path: ${cron_filename}"
echo ">>Cronjob schedule: ${cron_job_schedule}"

c_check_apache="E"
c_check_apacheup="E"
c_check_apache_enable="E"
c_check_tar_file="E"
c_check_awscli="E"
c_check_s3upload="E"
#--------------------------------------------------------------------------------------------------------------

#############################				 PACKAGE INSTALLATION  		   		  #############################


echo "Package Installation >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
echo ">>Updating apt-get......"
sudo apt-get update -y


#Check and install Apache2 server

apchpkgStatus=$(dpkg-query -W --showformat='${Status}\n' apache2|grep "install ok installed")
if [ "" = "$apchpkgStatus" ]; then
    echo ">>Installing Apache2 server......"
    sudo apt install apache2 -y
    apchpkgStatus2=$(dpkg-query -W --showformat='${Status}\n' apache2|grep "install ok installed")
    if [ "" = "$apchpkgStatus2" ]; then
        echo ">>Apache2 server installation failed."
        c_check_apache="E"
    else
        echo ">>Apache2 server installed successfully."
        c_check_apache="S"
    fi
else
    echo ">>Apache2 server is already installed."
    c_check_apache="S"
fi

#Check and install Apache2 service status
if [ ${c_check_apache} = "S" ]; then
    
    sudo systemctl is-active --quiet apache2

    if [ $? -eq 0 ]; then
        echo ">>Apache2 service is already up and running."
        c_check_apacheup="S"
    else
        echo ">>Starting Apache2 service......"
        sudo service apache2 start
        if [ $? -eq 0 ]; then
            echo ">>Apache2 service started successfully."
            c_check_apacheup="S"
        else
            echo ">>Failed to start Apache2 service."
            c_check_apacheup="E"
        fi
    fi
fi

if [ ${c_check_apache} = "S" ]; then
    #Check Apache2 service is enabled or not
    sudo systemctl is-enabled apache2
    if [ $? -eq 0 ]; then
        echo ">>Apache2 service is already enabled."
        c_check_apache_enable="S"
    else
        echo ">>Enabling Apache2 service......"
        sudo systemctl enable apache2
        sudo systemctl is-enabled apache2
        if [ $? -eq 0 ]; then
            echo ">>Apache2 service is enabled successfully."
            c_check_apache_enable="S"
        else
            echo ">>Failed to enable Apache2 service."
            c_check_apache_enable="E"
        fi
    fi
fi


#--------------------------------------------------------------------------------------------------------------


#############################					 Backup Logs	  		   		  #############################

echo "Creation of tar file >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
if [ -d "/var/log/apache2" ]; then
    tar -czf /tmp/${tarfilename} /var/log/apache2/*.log
    echo ">>Tar FileName: ${tarfilename}"
    if [ -f "/tmp/${tarfilename}" ]; then
        echo ">>Successfully created tarfile."
        c_check_tar_file="S"
    else
        echo ">>Tarfile creation failed."
        c_check_tar_file="E"
    fi
else
    c_check_tar_file="E"
    echo ">>'/var/log/apache2' does not exists"
fi

#--------------------------------------------------------------------------------------------------------------


#############################					 INSTALL AWS CLI	  		   		  ##########################

echo "AWC CLI Installation >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"

clipkgStatus=$(dpkg-query -W --showformat='${Status}\n' awscli|grep "install ok installed")
if [ "" = "$clipkgStatus" ]; then
    echo ">>Installing AWS CLI server......"
    sudo apt install awscli -y
    clipkgStatus2=$(dpkg-query -W --showformat='${Status}\n' awscli|grep "install ok installed")
    if [ "" = "$clipkgStatus2" ]; then
        echo ">>AWS CLI installation failed."
        c_check_awscli="E"
    else
        echo ">>AWS CLI installed successfully."
        c_check_awscli="S"
    fi
else
    echo ">>AWS CLI is already installed."
    c_check_awscli="S"
fi


#--------------------------------------------------------------------------------------------------------------

#############################			UPLOADING THE FILE IN S3 BUCKET(Archiving)	   		  ##########################

echo "Uploading Tar file to S3 bucket >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
if [ ${c_check_awscli} = "S" ] && [ ${c_check_tar_file} = "S" ]; then
    c_check_s3bucket=$(aws s3 ls|grep -w "${s3_bucket}"|wc -l)
    if [ $c_check_s3bucket = 1 ]; then
        aws s3 cp /tmp/${tarfilename} s3://${s3_bucket}/${tarfilename}
        c_check_s3bucket2=$(aws s3 ls s3://${s3_bucket}|grep -w "${tarfilename}"|wc -l)
        if [ $c_check_s3bucket2 = 1 ]; then
            c_check_s3upload="S"
            echo ">>'${tarfilename}' uploaded successfully."
        else
            c_check_s3upload="E"
            echo ">>'${tarfilename}' upload unsuccessful."
        fi
    else
        c_check_s3upload="E"
        echo ">>'${s3_bucket}' s3bucket does not exists."
    fi
else
    echo ">>Unable to upload the '${tarfilename}' file due to missing upload file or AWS CLI not installed properly."
    c_check_s3upload="E"
fi

#--------------------------------------------------------------------------------------------------------------

#############################			Logging Archiving Information	   		  ##########################

echo "Logging Archiving Information  >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
if [ ${c_check_tar_file} = "S" ] && [ ${c_check_s3upload} = "S" ]; then
    header="<h3>Log Type &emsp;&emsp;&emsp; Date Created &emsp;&emsp;&emsp; Type &emsp;&emsp;&emsp; Size</h3> "
    tarfilesize=$(aws s3 ls s3://${s3_bucket} --human-readable|grep -w "${tarfilename}"|awk '{print $3 $4}')
    content="<p>httpd-logs &emsp;&emsp;&emsp;&emsp; ${timestamp} &emsp;&emsp;&emsp;&emsp; tar &emsp;&emsp;&emsp;&emsp; ${tarfilesize} </p>"
        
    if [ -e $inv_filename ]
    then
        echo ">>Adding archive details to inventory.html file..."
        
        echo $content >> $inv_filename
        if grep -Fxq "${content}" $inv_filename
        then
            echo ">>Archive log inserted successfully."
        else
            echo ">>Archive log insertion unsuccessful."
        fi
    else
        echo ">>Inventory.html file does not exists. Creating the file..."
        
        echo $header > $inv_filename
        echo $content >> $inv_filename
        

        if [ ! -f $inv_filename ]; then
            echo ">>'$inv_filename' file creation failed."
        else
            echo ">>'$inv_filename' file created successfully."
            if grep -Fxq "${content}" $inv_filename
            then
                echo ">>Archive log inserted successfully."
            else
                echo ">>Archive log insertion unsuccessful."
            fi
        fi
    fi
else
    echo ">>Logging archiving information in 'inventory.html' file failed."
fi
#--------------------------------------------------------------------------------------------------------------


#############################			Create a Cron job	   		  ##########################


echo "Scheduling Task  >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"

if [ ! -f $cron_filename ]
then
    echo ">>Creating a Cron Job..."
    echo ">> ${cron_job_schedule}"
    echo "${cron_job_schedule}" >> $cron_filename
    
    if [ ! -f $cron_filename ]
    then
        echo ">>Failed to create Cronjob file and schedule the task"
    else
        echo ">>'$cron_filename' file created successfully."
        #verifying scheduling
        if grep -Fxq "${cron_job_schedule}" $cron_filename
        then
            echo ">>Scheduled successfully."
        else
            echo ">>Scheduling failed."
        fi
    fi
else
    echo ">>Cronjob file automation exists..."
    echo ">>Checking Existing Cronjob Schedule for the following..."
    echo ">> ${cron_job_schedule}"
    
    if grep -Fxq "${cron_job_schedule}" $cron_filename
    then
        echo ">>Already Scheduled."
    else
        echo "${cron_job_schedule}" >> $cron_filename
        #verifying scheduling
        if grep -Fxq "${cron_job_schedule}" $cron_filename
        then
            echo ">>Scheduled successfully."
        else
            echo ">>Scheduling failed."
        fi
    fi
    
fi


#############################			END	   		  ##########################
