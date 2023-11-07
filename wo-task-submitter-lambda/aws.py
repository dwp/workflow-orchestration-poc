import boto3
import botocore

def _get_resource(service: str):
    return boto3.client(service)

def invoke_lambda(function_name: str, payload: bytes = None) -> dict:
    c = _get_resource('lambda')
    return c.invoke(
        FunctionName=function_name,
        InvocationType='RequestResponse',
        Payload=payload
    )