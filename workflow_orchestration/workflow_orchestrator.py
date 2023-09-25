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
    command, task_name, extra_args = parse_path(event['path'])
    task = task_constructor(task_name, task_args)
    if command == "submit":
        resp = TaskSubmitter(task).submit()
    return resp

def parse_path(path: str):
    request = path.split("/")
    command = request[1]
    task_name = request[2]
    extra_args = None
    if len(request) > 3:
        extra_args = request[3:]
    return (command, task_name, extra_args)