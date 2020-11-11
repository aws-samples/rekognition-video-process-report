import json
import sys
import time
import os
import boto3

rek = boto3.client('rekognition')
sqs = boto3.client('sqs')
sns = boto3.client('sns')
s3 = boto3.client('s3')
start_job_id = ''


def GetJobID(event):
    '''
    Get the Identity code from the Queue
    '''
    for record in event['Records']:
        body = json.loads(record['body'])
        print(body)
        rek_message = json.loads(body["Message"])
        start_job_id = rek_message["JobId"]
        print('JOB ID: ', start_job_id)
    return start_job_id


def GetVideoName(event):
    '''
    Get the video name from the Queue
    '''
    for record in event['Records']:
        body = json.loads(record['body'])
        rek_message = json.loads(body["Message"])
        video = rek_message["Video"]
        video_name = video["S3ObjectName"]
        print('Nome do Video: ', video_name)
    return video_name


def GetFaceDetectionResults(start_job_id):
    max_results = 10
    pagination_token = ''
    finished = False
    content = []

    while not finished:
        response = rek.get_face_detection(JobId=start_job_id,
                                          MaxResults=max_results,
                                          NextToken=pagination_token)
        for FaceDetection in response['Faces']:
            reaction = {}
            face = FaceDetection['Face']
            reaction['Timestamp'] = FaceDetection['Timestamp']
            reaction['Confidence'] = face['Confidence']
            for instance in face['Emotions']:
                reaction[instance['Type']] = instance['Confidence']
                content.append(reaction)
        if 'NextToken' in response:
            pagination_token = response['NextToken']
        else:
            finished = True
    return content


def UploadVideo(content, video_name):
    video_name = video_name.replace('.mp4', '.json')
    bucket = os.getenv('BUCKET_NAME')
    key = f'analyzed_videos/{video_name}'
    print('Enviando arquivo ao S3')
    s3.put_object(
        Body=json.dumps(content),
        Bucket=bucket,
        Key=key
    )


def lambda_handler(event, context):
    start_job_id = GetJobID(event)
    content = GetFaceDetectionResults(start_job_id)
    video_name = GetVideoName(event)
    UploadVideo(content, video_name)
