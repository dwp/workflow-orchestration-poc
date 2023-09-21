import logging
from submitter import TaskSubmitter
from filter import task_constructor


LOGGER = logging.getLogger()
LOGGER.setLevel(logging.INFO)

task_args = {
    'launch_lambda': 'emr-launcher',
    'overrides': {
        'Name': 'local-cluster'
    }
}

def handler(event, context):
    LOGGER.info('Workflow Orchestrator Invoked!')
    # resp = EMRLauncher('emr-launcher', payload).launch()
    task = task_constructor('emr_launcher', task_args)
    resp = TaskSubmitter(task)
    return resp
