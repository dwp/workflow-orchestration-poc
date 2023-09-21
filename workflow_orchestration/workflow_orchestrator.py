import logging
import aws
import json

LOGGER = logging.getLogger()
LOGGER.setLevel(logging.INFO)

payload = {
    'overrides': {
        "Name": "new-cluster-name"
    }
}

def handler(event, context):
    LOGGER.info('Workflow Orchestrator Invoked!')
    resp = aws.invoke_lambda('emr-launcher', json.dumps(payload))
    r = json.loads(resp['Payload'].read().decode('utf-8'))
    return {
        "ClusterId": r['JobFlowId'],
        "ClusterArn": r['ClusterArn']
    }
