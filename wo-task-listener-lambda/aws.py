import boto3
import botocore
import logging

LOGGER = logging.getLogger()
LOGGER.setLevel(logging.INFO)

def _get_resource(service: str):
    return boto3.client(service)

def async_invoke_lambda(function_name: str, payload: bytes = None) -> dict:
    c = _get_resource('lambda')
    try:
        resp = c.invoke(
            FunctionName=function_name,
            InvocationType='Event',
            Payload=payload
        )
    except botocore.
    
    except Exception as e:
        LOGGER