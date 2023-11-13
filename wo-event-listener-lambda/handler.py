import logging
import os
from events import filter_event_from_kwargs
from aws import publish_to_sns

LOGGER = logging.getLogger()
LOGGER.setLevel(logging.INFO)

def handler(event, context):
    LOGGER.info("Workflow Orchestrator Task Listener Invoked!")
    event = filter_event_from_kwargs(**event)
    try:
        LOGGER.info(f"Constructed event: {event.to_json()}")
        resp = publish_to_sns(
            sns_topic_arn = os.environ.get("SNS_TOPIC_ARN"),
            payload=event.to_json(),
            group_id=event.group_id()
        )
        LOGGER.info(f"Published message with Id '{resp['MessageId']}'")
    except Exception as e:
        LOGGER.error(f"Unexpected Exception: {e}")