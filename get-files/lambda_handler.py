# This function is invoked by a s3:ObjectCreated:* event. It retrieves the object from the source bucket and prints it.

import boto3

def lambda_handler(event, context):
    s3 = boto3.client('s3')
    print(event)
    bucket = event['Records'][0]['s3']['bucket']['name']
    key = event['Records'][0]['s3']['object']['key']
    obj = s3.get_object(Bucket=bucket, Key=key)
    body = obj['Body'].read()
    print(body)
    return {
        'statusCode': 200,
        'body': body
    }
