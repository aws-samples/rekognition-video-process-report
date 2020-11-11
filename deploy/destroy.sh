#!/bin/bash
# Exit if any command fail
# set -e
clear

function check() {
    CMD="$1"
    eval "$CMD" &> /dev/null
    if [ "$?" -eq "0" ]
    then
        echo -e "\r\t\t\t\t\t\t[  OK  ]"
    else
        echo -e "\r\t\t\t\t\t\t[ FAIL ]"
        # exit 1
    fi
}

echo -n "Checking if AWS CLI is available..."
check 'aws --version'

echo -n "Checking if AWS Credentials are valid..."
check 'aws sts get-caller-identity'


cat <<EOF
---
Your system is updated and ready to begin destroy the solution
This will occur in 4 steps: Destroy the S3 Bucket based on your Account ID,
then destroy 3 Lambda Functions and SQS and then Sagemaker Notebook Instance.
---
EOF
sleep 3

echo -n 'Get Account ID : '
account=$(aws sts get-caller-identity --query Account --output text)
echo $account
sleep 3

echo -n 'Deleting S3 Buckets : '
BUCKET_CODE='sentiment-analysis-code-'$account
BUCKET='sentiment-analysis'$account
aws s3 rm s3://$BUCKET_CODE --recursive
aws s3 rm s3://$BUCKET --recursive
aws s3 rb s3://$BUCKET_CODE --force
sleep 5


echo -n 'Deleting CloudFormation stacks. :'

aws cloudformation delete-stack --stack-name emotions-backend-stack
aws cloudformation delete-stack --stack-name emotions-analysis-stack
sleep 4