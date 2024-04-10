import boto3

def lambda_handler(event, context):
    s3 = boto3.client('s3')
    print(event)
    s3.put_object(Bucket='new-test-bucket', Key='test.txt', Body=event['body'])
