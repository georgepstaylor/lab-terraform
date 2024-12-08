import os
import boto3
import json
import time
from datetime import datetime
from botocore.exceptions import ClientError
from boto3.dynamodb.conditions import Key, Attr


def handler(event, context):
    ses = boto3.client('ses')

    # Parse the message from SQS
    message_body = json.loads(event['Records'][0]['body'])

    # Extract email details from message
    sender = message_body['sender']
    recipient = message_body['recipient']
    subject = message_body['subject']
    body_text = message_body['body_text']
    body_html = message_body['body_html']

    try:
        response = ses.send_email(
            Source=sender,
            Destination={
                'ToAddresses': [
                    recipient,
                ],
            },
            Message={
                'Subject': {
                    'Data': subject,
                },
                'Body': {
                    'Text': {
                        'Data': body_text,
                    },
                    'Html': {
                        'Data': body_html,
                    }
                }
            }
        )
    except ClientError as e:
        print(e.response['Error']['Message'])
        raise e
    else:
        print(f"Email sent! Message ID: {response['MessageId']}")
        return {
            'statusCode': 200,
            'body': json.dumps('Email sent successfully!')
        }
