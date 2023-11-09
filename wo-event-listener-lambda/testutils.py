import json
import os
import time
from zipfile import ZipFile

import boto3
import botocore

CONFIG = botocore.config.Config(retries={'max_attempts': 0})
LAMBDA_ZIP = 'lambda.zip'


def get_lambda_client() -> boto3.client:
    return boto3.client(
        'lambda',
        aws_access_key_id='',
        aws_secret_access_key='',
        region_name='',
        endpoint_url='http://localhost:4566',
        config=CONFIG
    )


def create_lambda_zip(directory):
    def zipdir(path, ziphandler):
        for file in os.listdir(directory):
            if file.endswith('.py'):
                ziphandler.write(f'{directory}/{file}', file)
    with ZipFile(LAMBDA_ZIP, 'w') as ziphandler:
        zipdir(directory, ziphandler)


def create_lambda(function_name):
    lambda_client = get_lambda_client()
    create_lambda_zip('wo-task-listener-lambda')
    with open(LAMBDA_ZIP, 'rb') as f:
        zipped_code = f.read()
    resp = lambda_client.create_function(
        FunctionName=function_name,
        Runtime='python3.11',
        Role='arn:aws:iam::000000000000:role/lambda-role ',
        Handler='handler.handler',
        Code=dict(ZipFile=zipped_code),
        Timeout=120
    )
    return resp['FunctionArn']


def delete_lambda(function_name):
    lambda_client = get_lambda_client()
    lambda_client.delete_function(
        FunctionName=function_name
    )
    os.remove(LAMBDA_ZIP)


def wait_for_function(function_name):
    lambda_client = get_lambda_client()
    time.sleep(1)
    waiter = lambda_client.get_waiter('function_active_v2')
    waiter.wait(
        FunctionName=function_name
    )


def get_emr_client() -> boto3.client:
    return boto3.client(
        'emr',
        aws_access_key_id='',
        aws_secret_access_key='',
        region_name='',
        endpoint_url='http://localhost:4566',
        config=CONFIG
    )


def create_emr_cluster():
    emr_client = get_emr_client()
    response = emr_client.run_job_flow(
        Name='test-cluster',
        ReleaseLabel="emr-5.30.1",
        Instances={
            "MasterInstanceType": "m5.xlarge",
            "SlaveInstanceType": "m5.xlarge",
            "InstanceCount": 3,
            "KeepJobFlowAliveWhenNoSteps": False
        }
    )
    return response["JobFlowId"]

def terminate_emr_cluster(cluster_id: str):
    emr_client = get_emr_client()
    response = emr_client.terminate_job_flows(
        JobFlowIds=[cluster_id]
    )    

def get_sns_client() -> boto3.client:
    return boto3.client(
        'sns',
        aws_access_key_id='',
        aws_secret_access_key='',
        region_name='us-east-1',
        endpoint_url='http://localhost:4566',
        config=CONFIG
    )
    
def create_sns_topic(name: str) -> str:
    sns_client = get_sns_client()
    resp = sns_client.create_topic(
        Name=name
    )
    return resp['TopicArn']

def subscribe_lambda_to_sns(sns_topic_arn, lambda_arn: str) -> str:
    sns_client = get_sns_client()
    resp = sns_client.subscribe(
        TopicArn=sns_topic_arn,
        Protocol='lambda',
        Endpoint=lambda_arn
    )
    return resp['SubscriptionArn']

def get_eventbridge_client() -> boto3.client:
    return boto3.client(
        'events',
        aws_access_key_id='',
        aws_secret_access_key='',
        region_name='us-east-1',
        endpoint_url='http://localhost:4566',
        config=CONFIG
    )

def create_event_bus(name: str) -> str:
    event_client = get_eventbridge_client()
    resp = event_client.create_event_bus(
        Name=name
    )
    return resp['EventBusArn']

def delete_event_bus(name: str) -> None:
    event_client = get_eventbridge_client()
    event_client.delete_event_bus(name)
    
def put_event_rule(name, event_pattern, event_bus: str) -> str:
    event_client = get_eventbridge_client()
    resp = event_client.put_rule(
        Name=name,
        EventPattern=event_pattern,
        State='Enabled',
        EventBusName=event_bus
    )
    return resp['RuleArn']

def put_event_targets(rule, event_bus: str, targets: list) -> dict:
    event_client = get_eventbridge_client()
    resp = event_client.put_targets(
        Rule=rule,
        Targets=targets,
        EventBusName=event_bus
    )
    return resp