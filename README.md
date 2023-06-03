# Problem Description
The following infrastructure is created to install Apache2 web server in EC2 machine and run and enable it. Install aws cli if not installed and achive the log files in .tar format backup the file into the AWS S3 bucket.
Automate the whole archival and backup process by creating a cron job which runs the script everyday at '10:05:00' by creating a file 'automation'. In addition to that we also need to create a webpage 'inventory.html' file to track the archive logs from frontend.

## Version: Automation-v0.2
Pull request from tag Automation-v0.2.

## Prerequisites:
- IAM Role >> Full access to S3 bucket
- Security Group >> Open SSH, HTTP, HTTPS port
- Ubuntu EC2 Machine >> host machine
- S3 Bucket >> Data storage class

## Note:
#update the following parameters in 'automation.sh' file:
- s3_bucket="######"  >> enter your own s3 bucket name
- myname="######"  >> enter your file prefix name

## Following packages are installed:
#update the and install awscli
- sudo apt-get update
- sudo apt-get install awscli

#install apache2
- sudo apt-get update -y
- sudo apt install apache2
- sudo ufw app list
- sudo ufw allow 'Apache'
- sudo ufw status
- sudo systemctl status apache2

## Execution Steps:

#become root user
- sudo su

#move to /root directory
- cd /root

#clone Repository
- git clone https://github.com/KaustuvGupta/Automation_Project.git

#move into the Repository
- cd Automation_Project

#update Parameters in automation.sh file or run using runtime parameter

- update the bucket parameter s3_bucket and myname as mentioned in the above notes

#Check Tag Automation-v0.2
- git checkout main

- bash -x ./automation.sh
