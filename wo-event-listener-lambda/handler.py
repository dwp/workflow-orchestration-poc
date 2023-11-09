import logging
import json
from events import filter_event_from_kwargs
from aws import async_invoke_lambda

LOGGER = logging.getLogger()
LOGGER.setLevel(logging.INFO)

def handler(event, context):
    LOGGER.info("Workflow Orchestrator Task Listener Invoked!")
    event = filter_event_from_kwargs(**json.loads(event))
    try:
        LOGGER.info(f"Constructed event: {event.to_json()}")
        resp = async_invoke_lambda("workflow_orchestration_task_submitter", event.to_json())
        payload = json.loads(resp["Payload"].read())
        rc = payload["statusCode"]
        if rc != "202":
            LOGGER.error(f"Non 202 exit code from lambda: '{rc}'")
    except Exception as e:
        LOGGER.error(f"Unexpected Exception: {e}")