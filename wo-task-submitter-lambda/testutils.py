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
    create_lambda_zip('wo-task-submitter-lambda')
    with open(LAMBDA_ZIP, 'rb') as f:
        zipped_code = f.read()
    lambda_client.create_function(
        FunctionName=function_name,
        Runtime='python3.11',
        Role='arn:aws:iam::000000000000:role/lambda-role ',
        Handler='handler.handler',
        Code=dict(ZipFile=zipped_code),
        Timeout=120
    )


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


def invoke_function_and_get_message(function_name):
    lambda_client = get_lambda_client()
    response = lambda_client.invoke(
        FunctionName=function_name,
        InvocationType='RequestResponse'
    )
    return json.loads(
        response['Payload']
        .read()
        .decode('utf-8')
    )
