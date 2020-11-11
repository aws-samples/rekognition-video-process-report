import json
import sys
import time
import os
import boto3

rek = boto3.client('rekognition')
sqs = boto3.client('sqs')
sns = boto3.client('sns')
s3 = boto3.client('s3')

role_arn = os.getenv('role_arn')
sns_arn = os.getenv('sns_arn')

def StartFaceDetection(event):
    bucket = event['Records'][0]['s3']['bucket']['name']
    video = event['Records'][0]['s3']['object']['key']

    print('Video novo sendo processado: ', video, ', ', bucket)
    response = rek.start_face_detection(Video={'S3Object': {'Bucket': bucket, 'Name': video}},
                                        FaceAttributes='ALL',
                                        NotificationChannel={'RoleArn': role_arn, 'SNSTopicArn': sns_arn})
    startJobId = response['JobId']
    print('Start Job Id: ' + startJobId)
    return startJobId


def lambda_handler(event, context):
    StartFaceDetection(event)