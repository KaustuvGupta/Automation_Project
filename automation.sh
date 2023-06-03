#!/bin/bash
#Author			: Kaustuv Gupta
#Creation Date  	: 27/05/2023
#Version		: Automation-v0.1
#Change Variable 	: s3_bucket,myname in the VARABLE DECLARATION section
#--------------------------------------------------------------------------------------------------------------
#############################				 VARABLE DECLARATION		   		  #############################

echo "Variable Declaration >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
#update the following variables
s3_bucket="######"
myname="######"

timestamp=$(date '+%d%m%Y-%H%M%S')
tarfilename=${myname}-httpd-logs-${timestamp}.tar

echo ">>Bucket Name: ${s3_bucket}"
echo ">>My Name: ${myname}"
echo ">>TimeStamp: ${timestamp}"

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

#############################			END	   		  ##########################
