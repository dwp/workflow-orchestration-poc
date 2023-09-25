import logging
import json
from submitter import TaskSubmitter
from filter import task_constructor


LOGGER = logging.getLogger()
LOGGER.setLevel(logging.INFO)

def handler(event, context):
    LOGGER.info('Workflow Orchestrator Invoked!')
    command, task_name, extra_args = parse_request_path(event.get('path'))
    request_body = event.get('body', {})
    task = task_constructor(task_name, json.loads(request_body))
    if command == "submit":
        resp = TaskSubmitter(task).submit()
    return resp

def parse_request_path(path: str) -> tuple:
    request = path.split("/")
    command = request[1]
    task_name = request[2]
    extra_args = None
    if len(request) > 3:
        extra_args = request[3:]
    return (command, task_name, extra_args)
