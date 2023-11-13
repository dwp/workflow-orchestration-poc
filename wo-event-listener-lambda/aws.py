import boto3
import logging

LOGGER = logging.getLogger()
LOGGER.setLevel(logging.INFO)

def _get_resource(service: str):
    return boto3.client(service)

def publish_to_sns(sns_topic_arn: str, message: str, group_id: str):
    c = _get_resource('sns')
    return c.publish(
        TopicArn=sns_topic_arn,
        Message=message,
        MessageStructure='json',
        MessageGroupId=group_id
    )
