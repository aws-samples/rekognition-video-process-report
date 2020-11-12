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
Your system is updated and ready to begin deploying the solution
This will occur in 4 steps: Create an S3 Bucket based on your Account ID,
then create 3 Lambda Functions and SQS and then Sagemaker Notebook Instance.
---
EOF
sleep 3

echo -n 'Get Account ID : '
account=$(aws sts get-caller-identity --query Account --output text)
echo $account

sleep 3

echo -n 'Get Region : '
region=$(aws configure get region)
echo $region

sleep 3

echo -n 'Creating S3 Bucket : '
BUCKET_CODE='sentiment-analysis-code-'$account
BUCKET='sentiment-analysis-'$account

aws s3 mb s3://$BUCKET_CODE

echo -n 'Uploading the code of the Lambda Functions to S3  : '
aws s3 cp ../code/rekognition-get-emotions/lambda_get_emotions.zip s3://$BUCKET_CODE/code/
aws s3 cp ../code/rekognition-get-faces/lambda_get_faces.zip s3://$BUCKET_CODE/code/

sleep 3

echo -n 'Creating the Lambda Stack  :'
aws cloudformation create-stack --stack-name emotions-backend-stack --template-body file://lambda.yml --parameters ParameterKey=BucketName,ParameterValue=$BUCKET ParameterKey=BucketNameCode,ParameterValue=$BUCKET_CODE --capabilities CAPABILITY_NAMED_IAM
sleep 3

echo -n 'Creating the Sagemaker Notebook Instance :'
aws cloudformation create-stack --stack-name emotions-analysis-stack --template-body file://notebook.yml --capabilities CAPABILITY_NAMED_IAM
sleep 10

echo -n 'Final Adjustments: '
aws sns subscribe --topic-arn arn:aws:sns:$region:$account:rekognition-video-analysis-topic --protocol sqs --notification-endpoint arn:aws:sqs:$region:$account:rekognition-video-analysis-queue
sleep 30

aws lambda update-function-configuration \
    --function-name lambda-get-faces \
    --environment Variables="{role_arn=arn:aws:iam::$account:role/role-rekognition-video-analysis-cf,sns_arn=arn:aws:sns:$region:$account:rekognition-video-analysis-topic}"

echo -n ' The deployment were finished. : '
sleep 3
