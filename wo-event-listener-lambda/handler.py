import logging
import os
from events import filter_event_from_kwargs
from aws import publish_to_sns

LOGGER = logging.getLogger()
LOGGER.setLevel(logging.INFO)

def handler(event, context):
    LOGGER.info("Workflow Orchestrator Event Listener Invoked!")
    event = filter_event_from_kwargs(**event)
    try:
        LOGGER.info(f"Constructed event: {event.to_json()}")
        LOGGER.info(f"Event Group ID: {event.group_id()}")
        sns_topic_arn = os.environ.get("SNS_TOPIC_ARN")
        if sns_topic_arn:
            LOGGER.info(f"Publishing event to SNS Topic with ARN: {sns_topic_arn}")
            resp = publish_to_sns(
                sns_topic_arn = sns_topic_arn,
                message=event.to_json(),
                deduplication_id=event.uid(),
                group_id=event.group_id()
            )
            LOGGER.info(f"Published message with Id '{resp['MessageId']}'")
        else:
            LOGGER.fatal("No SNS_TOPIC_ARN in Environment.")
    except Exception as e:
        LOGGER.error(f"Unexpected Exception: {e}")